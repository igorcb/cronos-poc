# Story 5.9: Modal Computar Horas (TaskItem) ao Clicar na Tarefa

**Status:** done
**Domínio:** DM-005-visualizacao-totalizadores
**Data:** 2026-04-22
**Epic:** Epic 5 — Visualização & Dashboard
**Story ID:** 5.9
**Story Key:** 5-9-modal-computar-horas-task-item

---

## Story

**Como** Igor (usuário do sistema),
**Quero** lançar horas trabalhadas em uma tarefa clicando nela na lista do dashboard,
**Para que** eu registre o tempo sem sair do dashboard e veja os totalizadores atualizando em tempo real.

---

## Acceptance Criteria

**AC1 — Abertura do modal:**
- Ao clicar em qualquer linha de tarefa na lista "Tarefas do Mês" do dashboard, abre um modal
- A página de fundo (dashboard) NÃO faz reload
- Modal implementado com Turbo Frame (`<turbo-frame id="modal">`)
- A linha da tarefa deve ser clicável (cursor pointer, hover sutil)

**AC2 — Conteúdo do modal — Formulário (parte superior):**
- Título: nome da tarefa (ex: "14335 - Fix Agreement Cancellation")
- Subtítulo: empresa + projeto
- Formulário para novo `task_item` com os campos:
  - **Hora Início** (`start_time`) — obrigatório, input time
  - **Hora Fim** (`end_time`) — obrigatório, input time
  - **Data** (`work_date`) — obrigatório, default: hoje, pode ser alterado
  - **Status** (`status`) — select com opções: `pending` / `completed`
- Horas trabalhadas calculadas automaticamente (Fim - Início) — exibidas após preenchimento
- Botão "Lançar Horas"

**AC3 — Conteúdo do modal — Histórico (parte inferior):**
- Seção "Histórico de Horas" abaixo do formulário
- Lista todos os `task_items` existentes da tarefa, ordenados por `created_at desc`
- Cada item exibe: data, hora início, hora fim, horas trabalhadas, status badge
- Se não há histórico: mensagem "Nenhum lançamento ainda"

**AC4 — Após lançar horas com sucesso:**
- Modal permanece aberto (não fecha)
- Histórico atualiza automaticamente via Turbo Stream (novo item aparece no topo da lista)
- Totalizadores do dashboard atualizam em tempo real:
  - "Horas Hoje" atualiza se o lançamento for do dia atual
  - "Horas Mês" atualiza
  - "Valor Mês" atualiza

**AC5 — Erro de validação:**
- Modal permanece aberto
- Erros exibidos inline
- Histórico permanece visível

**AC6 — Fechar modal:**
- Botão "Fechar" ou "×" fecha o modal
- Tecla `Escape` fecha o modal
- Clicar fora do modal (overlay) fecha o modal

**AC7 — Dark theme:**
- Consistente com o restante do sistema (`bg-gray-800`, `bg-gray-700`, `text-white`)

---

## Contexto Técnico

### Schema de `task_items` atual
```ruby
create_table "task_items" do |t|
  t.time "start_time", null: false
  t.time "end_time", null: false
  t.decimal "hours_worked", precision: 10, scale: 2, null: false  # calculado automaticamente
  t.string "status", default: "pending", null: false  # pending / completed
  t.bigint "task_id", null: false
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
end
```

> **Nota:** `task_items` não tem campo `date` atualmente. A "data" do lançamento é inferida por `created_at`. Para permitir lançamento em datas passadas, será necessário adicionar `work_date` (date, nullable, default: hoje) via migration.

### Migration adicional necessária
```ruby
add_column :task_items, :work_date, :date, default: -> { "CURRENT_DATE" }
```

### Rota para criar task_item
```
POST /tasks/:task_id/task_items
```
Já existe em `routes.rb`: `resources :task_items, only: [:create, :update, :destroy]` nested em tasks.

### Fluxo Turbo Frame

```
1. Usuário clica na linha da tarefa no dashboard
2. GET /tasks/:id/task_items/new (com header Turbo-Frame: modal)
   → Novo endpoint/action a criar: TaskItemsController#new
3. Modal abre com formulário + histórico
4. Usuário preenche e submete
5. POST /tasks/:task_id/task_items
6. Se válido: Turbo Stream atualiza:
   a. Prepend do novo task_item no histórico dentro do modal
   b. Limpa o formulário (ou mantém para próximo lançamento)
   c. Atualiza totalizadores no dashboard
7. Se inválido: re-renderiza form com erros dentro do modal
```

### Novo endpoint necessário
```ruby
# app/controllers/task_items_controller.rb
def new
  @task = Task.find(params[:task_id])
  @task_item = @task.task_items.build(work_date: Date.current)
  @task_items = @task.task_items.recent_first
end
```

### View do modal (`app/views/task_items/new.html.erb`)
```erb
<turbo-frame id="modal">
  <div class="modal-overlay" data-controller="modal" data-action="keydown.escape@window->modal#close click->modal#closeOnOverlay">
    <div class="modal-card bg-gray-800 rounded-lg p-6 max-w-lg w-full">
      <!-- Header -->
      <div class="flex justify-between mb-4">
        <div>
          <h2 class="text-white font-bold"><%= @task.display_name %></h2>
          <p class="text-gray-400 text-sm"><%= @task.company.name %> · <%= @task.project.name %></p>
        </div>
        <button data-action="modal#close" aria-label="Fechar">×</button>
      </div>

      <!-- Formulário -->
      <%= form_with model: [@task, @task_item], data: { turbo_frame: "task-items-list" } do |f| %>
        <!-- start_time, end_time, work_date, status -->
        <%= f.submit "Lançar Horas" %>
      <% end %>

      <!-- Histórico -->
      <turbo-frame id="task-items-list">
        <h3 class="text-gray-400 text-sm mt-6 mb-2">Histórico de Horas</h3>
        <%= render partial: "task_items/list", locals: { task_items: @task_items } %>
      </turbo-frame>
    </div>
  </div>
</turbo-frame>
```

### Rota adicional para `new`
```ruby
resources :tasks, only: [:index, :new, :create, :edit, :update, :destroy] do
  resources :task_items, only: [:new, :create, :update, :destroy]
end
```

---

## Guardrails

- **NÃO** fechar o modal após lançar horas — usuário pode querer lançar múltiplos itens
- **NÃO** remover o comportamento atual de `TaskItemsController#create` (Turbo Stream de totalizadores)
- **NÃO** tornar `work_date` obrigatório no model — manter `allow_nil: false` mas com default de hoje
- O cálculo de `hours_worked` já é automático via `before_save :calculate_hours_worked` no model — não recriar
- `task_items.status` aceita apenas `pending` / `completed` — conforme enum existente
- Linha clicável no dashboard deve usar `data-turbo-frame="modal"` apontando para `new_task_task_item_path(task)`

---

## Dev Agent Record

### Checklist de Implementação
- [x] Migration: `add_column :task_items, :work_date, :date`
- [x] Model `TaskItem`: incluir `work_date` nas validações (presence, default hoje)
- [x] Rota: adicionar `new` em `task_items` nested em tasks
- [x] `TaskItemsController#new`: carregar task, build task_item, carregar histórico
- [x] `task_items/new.html.erb`: modal com form + histórico dentro de turbo-frame
- [x] `task_items/_list.html.erb`: partial do histórico (turbo-frame atualizável)
- [x] `task_items_controller#create` turbo stream: atualizar histórico dentro do modal + totalizadores dashboard
- [x] `dashboard/_task_row.html.erb`: linhas da tabela clicáveis com `data-turbo-frame="modal"`
- [x] `modal_controller.js`: reutilizado da story 5.8 (fechar com Escape e overlay click)
- [x] Strong params: incluir `work_date`
- [x] Spec: lançar task_item via modal atualiza histórico e totalizadores
- [x] Testes passando sem regressão (707 examples, 0 failures)

### Notas de Implementação

**2026-04-23 — Amelia (Dev Agent)**

- Migration com `default: -> { "CURRENT_DATE" }` aplicada com sucesso
- Model: `before_validation :set_work_date_default` para garantir Date.current quando nil
- Rota `new` adicionada em task_items nested em tasks
- `TaskItemsController#new` retorna @task, @task_item (com work_date=hoje) e @task_items
- View `new.html.erb` usa `turbo-frame#modal` com form + `turbo-frame#task-items-list-{task.id}` para histórico
- Partial `_modal_form.html.erb` criado para re-renderizar modal em caso de erro de validação via Turbo Stream
- Partial `_list.html.erb` exibe histórico com data, horários, horas e status badge
- `create` em caso de sucesso: update do histórico no modal + totalizadores; em caso de erro: replace do modal completo com erros
- Dashboard `_task_row.html.erb`: link com `data-turbo-frame="modal"` + onclick para clicar em qualquer parte da linha
- `modal_controller.js` reutilizado sem alterações (fechar via Escape e overlay click já funcionavam)
- Factory `:task_item` atualizada com `work_date { Date.current }`
- Specs novos: GET #new (autenticação, template, work_date padrão, ordenação), turbo_stream create (task-items-list target), work_date params

### File List
- `db/migrate/20260423193749_add_work_date_to_task_items.rb` — nova migration
- `app/models/task_item.rb` — validação work_date + set_work_date_default
- `config/routes.rb` — :new adicionado em task_items
- `app/controllers/task_items_controller.rb` — #new + #create atualizado + strong params
- `app/views/task_items/new.html.erb` — nova view do modal
- `app/views/task_items/_list.html.erb` — novo partial do histórico
- `app/views/task_items/_modal_form.html.erb` — novo partial para re-render em erro
- `app/views/dashboard/_task_row.html.erb` — linhas clicáveis
- `spec/factories/task_items.rb` — work_date adicionado
- `spec/controllers/task_items_controller_spec.rb` — specs GET #new e work_date
