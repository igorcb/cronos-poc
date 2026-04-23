# Story 5.8: Modal Nova Tarefa no Dashboard

**Status:** done
**Domínio:** DM-005-visualizacao-totalizadores
**Data:** 2026-04-22
**Epic:** Epic 5 — Visualização & Dashboard
**Story ID:** 5.8
**Story Key:** 5-8-modal-nova-tarefa-no-dashboard

---

## Story

**Como** Igor (usuário do sistema),
**Quero** criar uma nova tarefa através de um modal no dashboard sem sair da página,
**Para que** eu mantenha o contexto do dashboard e a lista de tarefas atualize automaticamente após o cadastro.

---

## Acceptance Criteria

**AC1 — Abertura do modal:**
- Ao clicar no ícone `+` do dashboard (story 5.7), abre um modal sobreposto à página
- A página de fundo (dashboard) NÃO faz reload/redirect
- O modal é implementado com Turbo Frame (`<turbo-frame id="modal">`)

**AC2 — Conteúdo do modal:**
- Título: "Nova Tarefa"
- Formulário com **todos** os campos atuais de `tasks/new`:
  - Código (opcional, numérico — story 4.13)
  - Nome da Tarefa (obrigatório)
  - Empresa (obrigatório, select)
  - Projeto (obrigatório, select dinâmico via `project_selector_controller`)
  - Data de Início (obrigatório, default: hoje)
  - Horas Estimadas (obrigatório)
  - Status (obrigatório, select)
  - Notas (opcional, textarea)
- Botões: "Salvar" e "Cancelar"
- Validação client-side com `form_validation_controller` (padrão story 1.10)

**AC3 — Após salvar com sucesso:**
- Modal fecha automaticamente
- Lista "Tarefas do Mês" no dashboard atualiza via Turbo Stream (sem refresh de página)
- Totalizadores (Horas Hoje, Horas Mês, Valor Mês) atualizam automaticamente

**AC4 — Erro de validação:**
- Modal permanece aberto
- Erros exibidos inline nos campos (padrão existente)
- NÃO redireciona para outra página

**AC5 — Fechar modal:**
- Botão "Cancelar" fecha o modal sem salvar
- Tecla `Escape` fecha o modal
- Clicar fora do modal (overlay) fecha o modal

**AC6 — Dark theme:**
- Modal com fundo `bg-gray-800`, overlay `bg-black/50`
- Padrão visual consistente com o restante do sistema

---

## Arquitetura Técnica

### Abordagem: Turbo Frame + Turbo Stream

O modal é renderizado via Turbo Frame. O ícone `+` aponta para `new_task_path` com `data-turbo-frame="modal"`. O layout base deve conter um `<turbo-frame id="modal">` vazio.

### Fluxo

```
1. Usuário clica no ícone +
2. GET /tasks/new (com header Turbo-Frame: modal)
3. Controller renderiza tasks/new — view retorna apenas o conteúdo do modal dentro do turbo-frame
4. Modal aparece sobreposto ao dashboard
5. Usuário preenche e submete
6. POST /tasks (com header Turbo-Frame: modal)
7. Se válido: controller responde com Turbo Stream para:
   a. Limpar o turbo-frame#modal (fechar modal)
   b. Atualizar a lista de tarefas no dashboard (turbo-stream replace/prepend)
8. Se inválido: re-renderiza o form dentro do modal com erros
```

### Mudanças necessárias

**`app/views/layouts/application.html.erb`:**
```erb
<!-- Adicionar antes de </body> -->
<turbo-frame id="modal"></turbo-frame>
```

**Ícone + no dashboard (`dashboard/index.html.erb`):**
```erb
<%= link_to new_task_path, data: { turbo_frame: "modal" }, aria: { label: "Nova Tarefa" } do %>
  <div class="flex-shrink-0 bg-blue-900 rounded-md p-3 inline-flex hover:bg-blue-800 transition">
    <svg class="h-6 w-6 text-blue-400" ...>+</svg>
  </div>
<% end %>
```

**`app/views/tasks/new.html.erb`:**
- Envolver conteúdo em `<turbo-frame id="modal">`
- Quando renderizado dentro do frame: exibir como modal (overlay + card)
- Quando acessado diretamente (`/tasks/new`): renderizar normalmente (sem overlay)

**`app/controllers/tasks_controller.rb` — action `create`:**
```ruby
def create
  @task = Task.new(task_params)
  if @task.save
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("modal", ""),           # fecha modal
          turbo_stream.prepend("tasks-list", partial: "tasks/task_row", locals: { task: @task })
        ]
      end
      format.html { redirect_to tasks_path }
    end
  else
    render :new, status: :unprocessable_content
  end
end
```

**Stimulus controller para fechar modal (`modal_controller.js`):**
```javascript
// Fecha modal ao pressionar Escape ou clicar no overlay
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  close() {
    document.querySelector("turbo-frame#modal").innerHTML = ""
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close()
  }
}
```

### Partial da lista do dashboard

O dashboard precisa de um elemento com `id="tasks-list"` para o Turbo Stream fazer prepend:
```erb
<tbody id="tasks-list">
  <% @tasks.each do |task| %>
    <%= render "tasks/task_row", task: task %>
  <% end %>
</tbody>
```

---

## Guardrails

- **NÃO** fazer redirect para `/tasks` após criar via modal — usar Turbo Stream
- **NÃO** usar `render turbo_stream` em `/tasks/new` direto — o frame já lida com isso
- **NÃO** remover a rota/view `/tasks/new` existente — o modal reutiliza ela
- **NÃO** quebrar o fluxo normal de criação de task fora do dashboard
- O `project_selector_controller` existente deve funcionar dentro do modal
- O `form_validation_controller` existente deve funcionar dentro do modal

---

## Dev Agent Record

### Checklist de Implementação
- [x] `application.html.erb`: adicionar `<turbo-frame id="modal"></turbo-frame>`
- [x] `dashboard/index.html.erb`: ícone + com `data-turbo-frame="modal"`, tbody com `id="tasks-list"`
- [x] `tasks/new.html.erb`: envolver em `<turbo-frame id="modal">` com overlay modal
- [x] `tasks_controller#create`: responder com Turbo Stream (fechar modal + prepend lista)
- [x] `modal_controller.js`: criado e registrado em `index.js`
- [x] Overlay fecha com Escape e clique fora
- [x] Spec: criar task via modal atualiza lista sem reload
- [x] Testes passando sem regressão

### Notas de Implementação

- `tasks/new.html.erb` detecta renderização dentro do frame via `request.headers["Turbo-Frame"] == "modal"` para exibir overlay, ou renderização normal quando acessado diretamente.
- `tasks_controller#create` verifica o mesmo header: se modal, responde com dois Turbo Streams (`update#modal` + `prepend#tasks-list`); se não, redireciona.
- `modal_controller.js` registra listener de `keydown` em `connect`/`disconnect` para fechar com Escape. Overlay fecha via `data-action="click->modal#closeOnOverlayClick"` no elemento pai.
- `dashboard/index.html.erb` reestruturado para sempre renderizar o `tbody#tasks-list` (mesmo vazio), garantindo que o `turbo_stream.prepend` funcione ao criar a primeira tarefa do mês.
- `dashboard/_task_row.html.erb` criado como partial reutilizável para o Turbo Stream prepend.
- Spec de acessibilidade atualizado para refletir a mudança da story 5.7 (seção "Ações Rápidas" substituída por ícone +).
- 692 exemplos passando, 0 falhas.

### File List
- `app/views/layouts/application.html.erb` (modificado)
- `app/views/dashboard/index.html.erb` (modificado)
- `app/views/dashboard/_task_row.html.erb` (criado)
- `app/views/dashboard/_daily_hours.html.erb` (criado)
- `app/views/dashboard/_monthly_hours.html.erb` (criado)
- `app/views/dashboard/_monthly_value.html.erb` (criado)
- `app/views/tasks/new.html.erb` (modificado)
- `app/controllers/tasks_controller.rb` (modificado)
- `app/controllers/dashboard_controller.rb` (modificado)
- `app/javascript/controllers/modal_controller.js` (criado)
- `app/javascript/controllers/index.js` (modificado)
- `config/locales/pt-BR.yml` (modificado)
- `spec/requests/dashboard_modal_nova_tarefa_spec.rb` (criado)
- `spec/requests/accessibility_spec.rb` (modificado)

### Change Log
- 2026-04-23: Implementação completa da story 5.8 — Modal Nova Tarefa no Dashboard via Turbo Frame + Turbo Stream. 26 specs novos, 692 total sem falhas.
- 2026-04-23: Correções QA — HIGH-1: totalizadores dinâmicos no dashboard (DashboardController + 3 partials + Turbo Streams no create); HIGH-2: campo status adicionado na versão não-modal; MED-1: labels status traduzidos (pt-BR.yml); MED-2: guard enum + remoção de linha redundante. 700 specs, 0 falhas.
