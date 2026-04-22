# Story 5.8: Modal Nova Tarefa no Dashboard

**Status:** ready-for-dev
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
- [ ] `application.html.erb`: adicionar `<turbo-frame id="modal"></turbo-frame>`
- [ ] `dashboard/index.html.erb`: ícone + com `data-turbo-frame="modal"`, tbody com `id="tasks-list"`
- [ ] `tasks/new.html.erb`: envolver em `<turbo-frame id="modal">` com overlay modal
- [ ] `tasks_controller#create`: responder com Turbo Stream (fechar modal + prepend lista)
- [ ] `modal_controller.js`: criado e registrado em `index.js`
- [ ] Overlay fecha com Escape e clique fora
- [ ] Spec: criar task via modal atualiza lista sem reload
- [ ] Testes passando sem regressão

### Notas de Implementação
_(Preencher pelo dev agent)_
