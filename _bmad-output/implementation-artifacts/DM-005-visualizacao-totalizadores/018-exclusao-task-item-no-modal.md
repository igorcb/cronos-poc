# Story 5.18: Exclusão de Lançamento de Horas no Modal de Histórico

**Status:** ready-for-dev
**Domínio:** DM-005-visualizacao-totalizadores
**Data:** 2026-05-05
**Epic:** Epic 5 — Visualização & Dashboard
**Story ID:** 5.18
**Story Key:** 5-18-exclusao-task-item-no-modal

---

## Contexto

O modal de lançamento de horas permite editar lançamentos existentes (story 5.17), mas não permite excluí-los. Em produção, um lançamento duplicado (`18:00–18:58` para a tarefa `20182`) distorceu os totais de horas do dia: o sistema exibiu `12:55` em vez do correto `11:57` (diferença de exatamente 58 minutos — o lançamento duplicado). Sem botão de exclusão, o único recurso é acesso direto ao banco de dados.

**Decisão arquitetural:** DA-035 — botão lixeira por linha do histórico, `DELETE` com confirmação via `data-turbo-confirm`, recálculo automático de `validated_hours` e atualização de Turbo Streams.

---

## História do Usuário

**Como** usuário do Cronos POC,
**Quero** clicar em um ícone de lixeira ao lado de um lançamento no histórico do modal,
**Para** remover lançamentos incorretos ou duplicados e manter os totais de horas precisos.

---

## Critérios de Aceite

- [ ] **AC1 — Ícone lixeira no histórico:** cada item do histórico exibe botão lixeira à direita do botão lápis, exceto quando `task.delivered?` (ocultar o botão)
- [ ] **AC2 — Confirmação antes de excluir:** ao clicar na lixeira, exibe confirmação: `"Tem certeza que deseja remover este lançamento?"`
- [ ] **AC3 — DELETE no item correto:** ao confirmar, envia `DELETE` para `task_task_item_path(task, item)` via Turbo Stream
- [ ] **AC4 — Lista atualiza após exclusão:** o item removido desaparece do histórico e o `Total: HH:MM` do cabeçalho é recalculado
- [ ] **AC5 — validated_hours da Task recalculado:** após exclusão, `task.validated_hours` é recalculado automaticamente via callback existente (`recalculate_validated_hours`)
- [ ] **AC6 — KPIs do dashboard atualizam:** Horas Hoje, Horas Mês, Valor Hoje, Valor Mês e Est/Real são atualizados via Turbo Stream sem refresh

---

## Tasks / Subtasks

- [ ] **T1 — Botão lixeira em `_list.html.erb`** (AC1)
  - [ ] Adicionar `button_to` com `method: :delete` e `data-turbo-confirm` após o botão lápis existente
  - [ ] Condicional: ocultar quando `item.task.delivered?`
  - [ ] Classe visual: `bg-red-700 hover:bg-red-600`, mesmas dimensões do lápis (`w-6 h-6`)
  - [ ] SVG ícone lixeira (mesmo padrão do botão excluir na `/tasks`)

- [ ] **T2 — `TaskItemsController#destroy`** (AC3, AC5, AC6)
  - [ ] Verificar se action `destroy` já existe — se sim, ajustar o `respond_to` para incluir `format.turbo_stream`
  - [ ] Após `task_item.destroy`, recarregar `@task_items = @task.task_items.recent_first`
  - [ ] Renderizar Turbo Streams: lista do modal + KPIs do dashboard
  - [ ] Incluir `DashboardCalculations` se necessário (padrão já estabelecido)

- [ ] **T3 — Turbo Streams no destroy** (AC4, AC6)
  - [ ] `turbo_stream.update("task-items-list-#{@task.id}", ...)` — atualiza lista + Total no cabeçalho
  - [ ] `turbo_stream.replace("dashboard_daily_hours", ...)`
  - [ ] `turbo_stream.replace("dashboard_monthly_hours", ...)`
  - [ ] `turbo_stream.replace("dashboard_daily_value", ...)`
  - [ ] `turbo_stream.replace("dashboard_monthly_value", ...)`
  - [ ] `turbo_stream.replace("dashboard_daily_task_count", ...)`
  - [ ] `turbo_stream.replace("dashboard_monthly_task_count", ...)`
  - [ ] `turbo_stream.replace("task_row_#{@task.id}", ...)` — atualiza Est/Real no dashboard (se task_row existir)

- [ ] **T4 — Testes RSpec** (todos os ACs)
  - [ ] Request spec: `DELETE /tasks/:task_id/task_items/:id` — sucesso (turbo_stream)
  - [ ] Request spec: `DELETE` em task `delivered` — deve retornar erro (422)
  - [ ] Spec de componente: lixeira visível quando `pending`/`completed`, oculta quando `delivered`

---

## Dev Notes

### Padrão de referência: story 5.17 (edição)

A story 5.17 estabeleceu o padrão completo para ações no modal. A exclusão segue o mesmo padrão de Turbo Streams no `update`, apenas trocando por `destroy`.

**Arquivos tocados na 5.17:**
- `app/views/task_items/_list.html.erb` — botões de ação por item
- `app/views/task_items/_modal_form.html.erb` — script de event delegation
- `app/controllers/task_items_controller.rb` — Turbo Stream response

**Para a 5.18, apenas `_list.html.erb` e `tasks_controller.rb` precisam de mudança** — o modal_form NÃO precisa de alteração (a exclusão usa `button_to` nativo, não JS delegation).

### Botão lixeira — usar `button_to` nativo

A exclusão NÃO usa o padrão de JS delegation da edição. Usar `button_to` com `method: :delete` e `data: { turbo_confirm: "...", turbo_stream: true }`:

```erb
<% unless item.task.delivered? %>
  <%= button_to task_task_item_path(item.task, item),
                method: :delete,
                form_class: "inline-flex",
                class: "inline-flex items-center justify-center w-6 h-6 bg-red-700 hover:bg-red-600 text-white rounded transition",
                aria: { label: "Excluir lançamento" },
                data: { turbo_confirm: "Tem certeza que deseja remover este lançamento?", turbo_stream: true } do %>
    <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
            d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
    </svg>
  <% end %>
<% end %>
```

### `TaskItemsController#destroy` — padrão do `update`

O `destroy` deve espelhar o `update` nos Turbo Streams. Ver implementação atual do `update` em `app/controllers/task_items_controller.rb` como referência direta.

```ruby
def destroy
  if @task_item.destroy
    @task_items = @task.task_items.recent_first
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("task-items-list-#{@task.id}",
            partial: "task_items/list",
            locals: { task_items: @task_items }),
          turbo_stream.replace("dashboard_daily_hours",
            partial: "dashboard/daily_hours",
            locals: { daily_hours: calculate_daily_hours }),
          # ... demais streams (espelhar update)
        ]
      end
      format.html { redirect_to task_path(@task), notice: "Lançamento removido com sucesso" }
    end
  else
    respond_to do |format|
      format.turbo_stream { head :unprocessable_entity }
      format.html { redirect_to task_path(@task), alert: "Não foi possível remover o lançamento" }
    end
  end
end
```

### Recálculo automático — callback já existente

O `Task#recalculate_validated_hours` é chamado via `after_save` no `TaskItem`. No `destroy`, o callback `after_destroy` NÃO é chamado automaticamente — é necessário chamar `@task_item.task.recalculate_validated_hours` manualmente no controller OU verificar se o `dependent: :destroy` já dispara isso. **Verificar antes de implementar.**

### Atenção: `_list.html.erb` — variável `task` disponível?

Na story 5.17, o botão lápis usa `item.task` para obter o path. O partial `_list.html.erb` recebe apenas `task_items` como local. Usar `item.task` (associação carregada via `includes`) é seguro — não gera N+1 porque o `@task_items` é carregado com `@task.task_items`.

### Commits recentes relevantes

- `feat: exibir Total de horas no cabeçalho do histórico do modal` — moveu o total para o cabeçalho; o `_list.html.erb` não tem mais o rodapé de total (já removido). O novo `Total: HH:MM` está em `_modal_form.html.erb` e é recalculado ao renderizar `task-items-list-#{task.id}`.
- `fix: incluir DashboardCalculations no TasksController` — padrão: sempre verificar se `DashboardCalculations` está incluído antes de usar métodos do concern.

### Project Structure Notes

```
app/
  views/
    task_items/
      _list.html.erb          ← MODIFICAR: adicionar botão lixeira
      _modal_form.html.erb    ← NÃO modificar
  controllers/
    task_items_controller.rb  ← MODIFICAR: action destroy com Turbo Stream
spec/
  requests/
    task_items_controller_spec.rb  ← ADICIONAR: specs do destroy
```

### References

- [DA-035 — Exclusão de TaskItem](../../../planning-artifacts/DM-004-registro-tempo/architecture.md#da-035)
- [Story 5.17 — Edição no modal](./017-edicao-task-item-no-modal.md) — padrão de Turbo Streams
- [app/views/task_items/_list.html.erb](../../../../app/views/task_items/_list.html.erb) — botão lápis existente
- [app/controllers/task_items_controller.rb](../../../../app/controllers/task_items_controller.rb) — `#update` como referência

---

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Completion Notes List

### File List

### Debug Log References
