# Story 5.17: Edição de Lançamento de Horas no Mesmo Formulário do Modal

**Status:** done
**Domínio:** DM-005-visualizacao-totalizadores
**Data:** 2026-04-30
**Epic:** Epic 5 — Visualização & Dashboard
**Story ID:** 5.17
**Story Key:** 5-17-edicao-task-item-no-modal

---

## Contexto

O modal de lançamento de horas exibia o histórico de lançamentos (task_items) de uma task, mas não permitia editar registros existentes. O usuário precisava acessar outra tela para corrigir horários ou status de um lançamento já feito.

---

## História do Usuário

**Como** usuário do Cronos POC,
**Quero** clicar em um ícone de lápis ao lado de um lançamento no histórico do modal,
**Para** que o formulário principal do modal seja preenchido com os dados daquele lançamento e eu possa editá-lo sem sair do modal.

---

## Critérios de Aceite

- [x] **AC1 — Ícone de editar no histórico:** cada item do histórico de horas exibe um botão lápis à direita do badge de status
- [x] **AC2 — Formulário preenchido ao clicar:** ao clicar no lápis, o formulário principal (Hora Início, Hora Fim, Data, Status) é preenchido com os dados do lançamento selecionado
- [x] **AC3 — Botão muda para "Salvar Alterações":** o submit do formulário muda de "Lançar Horas" para "Salvar Alterações" indicando modo de edição
- [x] **AC4 — PATCH no item correto:** o formulário envia PATCH para `task_task_item_path(task, item)` ao invés de POST para criar novo
- [x] **AC5 — Histórico atualiza após salvar:** após o PATCH bem-sucedido, a lista do histórico reflete as alterações via Turbo Stream
- [x] **AC6 — KPIs do dashboard atualizam:** após edição, os totalizadores são recalculados e atualizados via Turbo Stream

---

## Análise Técnica

### Abordagem — JavaScript inline no modal (sem Stimulus)

O Stimulus não propaga `data-action` de elementos dentro de `turbo-frame` filhos para controllers em ancestrais. A solução adotada foi um event listener via delegation usando `<script>` inline no partial do modal, que escuta cliques nos botões `[data-edit-start]` dentro do modal.

### Botão editar em `_list.html.erb`

```erb
<button type="button"
        aria-label="Editar lançamento"
        data-edit-start="<%= item.start_time&.strftime("%H:%M") %>"
        data-edit-end="<%= item.end_time&.strftime("%H:%M") %>"
        data-edit-date="<%= item.work_date %>"
        data-edit-status="<%= item.status %>"
        data-edit-url="<%= task_task_item_path(item.task, item) %>"
        class="inline-flex items-center justify-center w-6 h-6 bg-gray-600 hover:bg-gray-500 text-white rounded transition">
  <!-- ícone lápis SVG -->
</button>
```

### Script de event delegation em `_modal_form.html.erb`

```javascript
(function() {
  var modal = document.querySelector('[data-controller~="modal"]');
  if (!modal) return;
  modal.addEventListener('click', function(e) {
    var btn = e.target.closest('button[data-edit-start]');
    if (!btn) return;
    var form = modal.querySelector('form');
    // Preenche campos do formulário
    form.querySelector("input[name$='[start_time]']").value = btn.dataset.editStart;
    form.querySelector("input[name$='[end_time]']").value   = btn.dataset.editEnd;
    form.querySelector("input[name$='[work_date]']").value  = btn.dataset.editDate;
    form.querySelector("select[name$='[status]']").value    = btn.dataset.editStatus;
    // Muda action para PATCH
    form.action = btn.dataset.editUrl;
    var old = form.querySelector("input[name='_method']");
    if (old) old.remove();
    var m = document.createElement('input');
    m.type = 'hidden'; m.name = '_method'; m.value = 'patch';
    form.prepend(m);
    // Muda label do botão
    var sub = form.querySelector("[type='submit']");
    if (sub) sub.value = 'Salvar Alterações';
    // Dispara cálculo de horas
    form.querySelector("input[name$='[start_time]']").dispatchEvent(new Event('change'));
    form.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
  });
})();
```

### `TaskItemsController#update`

Após salvar com sucesso, atualiza a lista do modal e os KPIs do dashboard:

```ruby
def update
  if @task_item.update(task_item_params)
    @task_items = @task.task_items.recent_first
    render turbo_stream: [
      turbo_stream.update("task-items-list-#{@task.id}", partial: "task_items/list", locals: { task_items: @task_items }),
      turbo_stream.replace("dashboard_daily_hours", ...),
      # ... demais KPIs
    ]
  end
end
```

---

## Arquivos Modificados

| Arquivo | Ação |
|---------|------|
| `app/views/task_items/_list.html.erb` | Adicionado botão lápis com `data-edit-*` em cada item |
| `app/views/task_items/_modal_form.html.erb` | Adicionado `<script>` com event delegation para preencher form |
| `app/controllers/task_items_controller.rb` | `#update` agora inclui stream para atualizar lista do modal |

---

## Estimativa

**1 story point** (~2h) — lógica JS de preenchimento de form + ajuste no controller.

---

## Dev Agent Record

### Decisão de Arquitetura

Tentativa 1: Stimulus controller `task-item-edit` com `data-action="task-item-edit#load"` — falhou porque `data-action` em elementos dentro de `turbo-frame` não é capturado por controller em ancestral.

Tentativa 2: Event delegation com `<script>` inline no partial — funcionou. Os dados do item são passados via `data-edit-*` attributes no botão, e o script popula o form ao clicar.

### Completion Notes

- ✅ AC1: Ícone lápis visível em cada item do histórico
- ✅ AC2: Formulário preenchido com dados do item ao clicar no lápis
- ✅ AC3: Submit muda para "Salvar Alterações"
- ✅ AC4: Form envia PATCH via `_method=patch` hidden input
- ✅ AC5: `turbo_stream.update("task-items-list-#{@task.id}")` atualiza o histórico após salvar
- ✅ AC6: Todos os KPIs do dashboard são atualizados via Turbo Stream no `#update`

### Change Log

- 2026-04-30: Implementação completa — botão editar no histórico, preenchimento do form via JS delegation, PATCH no controller
