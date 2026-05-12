# Story 6.1: Implementar Filtros por Empresa e Projeto

**Status:** done
**Domínio:** DM-006-filtros-dinamicos
**Data:** 2026-03-31
**Epic:** DM-006 — Filtros Dinâmicos
**Story ID:** 6.1
**Story Key:** 6-1-implementar-filtros-por-empresa-e-projeto

---

## Story

**Como** Igor,
**Quero** filtrar a listagem de tarefas por empresa e/ou projeto,
**Para que** eu veja apenas os dados relevantes para o fechamento mensal de cada cliente.

---

## Acceptance Criteria

**Given** que estou autenticado e acesso `/tasks`

**When** a página carrega

**Then**
1. Um formulário de filtros é exibido acima da tabela, com: select de "Empresa" e select de "Projeto"
2. Ambos os selects têm opção default "Todas as empresas" / "Todos os projetos"
3. Ao selecionar uma empresa e submeter, a listagem filtra: `@tasks.by_company(params[:company_id])`
4. Ao selecionar um projeto e submeter, a listagem filtra: `@tasks.by_project(params[:project_id])`
5. Filtros são combináveis: empresa + projeto ao mesmo tempo
6. A URL reflete os filtros aplicados: `/tasks?company_id=1&project_id=2`
7. Ao selecionar empresa, o dropdown de projetos atualiza para mostrar apenas projetos dessa empresa (reutiliza `project_selector_controller.js` existente)
8. Ao limpar os filtros (selecionar "Todas"), a listagem volta ao estado completo (mês atual)
9. Os totalizadores (`@daily_total` e `@company_monthly_totals`) são recalculados usando as tasks filtradas
10. Filtros aplicam em < 1s (NFR4)
11. `bundle exec rspec spec/controllers/tasks_controller_spec.rb` passa 100%
12. Todos os testes existentes continuam passando

---

## CRITICAL GUARDRAILS — Leia antes de implementar

### ⚠️ MODELO CORRETO: `Task`, NÃO `TimeEntry`

Não existe modelo `TimeEntry`. Toda a lógica é sobre `Task`. Os scopes já existem no modelo:
```ruby
# app/models/task.rb — já implementados
scope :by_status, ->(status) { where(status:) }
scope :by_company, ->(company_id) { where(company_id:) }
scope :by_project, ->(project_id) { where(project_id:) }
```

**Use `@tasks.by_company(params[:company_id])` — não recriar scopes.**

### ⚠️ Filtro de período padrão: mês atual — não remover

O `TasksController#index` filtra por `Date.current.all_month` por padrão. Este filtro deve ser **mantido como base**, e os filtros de empresa/projeto se aplicam **sobre** ele:

```ruby
def index
  @tasks = Task
    .includes(:company, :project, :task_items)
    .where(start_date: Date.current.all_month)   # ← MANTER sempre
    .order(start_date: :desc, created_at: :desc)

  @tasks = @tasks.by_company(params[:company_id]) if params[:company_id].present?
  @tasks = @tasks.by_project(params[:project_id]) if params[:project_id].present?

  @daily_total = calculate_daily_total
  @company_monthly_totals = calculate_company_totals(@tasks)  # ← passar @tasks filtradas
end
```

### ⚠️ `calculate_company_totals` precisa aceitar `tasks` como parâmetro

Atualmente `calculate_company_totals` é um método privado sem parâmetros que ignora filtros. Para que os totalizadores reflitam os filtros aplicados, precisa aceitar as tasks já filtradas como base:

```ruby
def calculate_company_totals(filtered_tasks = nil)
  base = filtered_tasks || Task.where(start_date: Date.current.all_month)
  Company
    .joins(tasks: :task_items)
    .where(tasks: { id: base.select(:id) })
    .group("companies.id", "companies.name", "companies.hourly_rate")
    .select(
      "companies.id",
      "companies.name",
      "companies.hourly_rate",
      "SUM(task_items.hours_worked) as total_hours"
    )
    .order("companies.name")
end
```

> **Nota:** os Turbo Stream responses em `create`, `update` e `destroy` chamam `calculate_company_totals` sem parâmetro — isso deve continuar funcionando (sem filtro = mês completo).

### ⚠️ Reutilizar `project_selector_controller.js` existente

O Stimulus controller `project_selector_controller.js` já faz fetch de `/projects/projects.json?company_id=X` para popular o dropdown de projetos dinamicamente. **Reutilize-o no formulário de filtros** em vez de criar um novo controller:

```erb
<div data-controller="project-selector">
  <%= select_tag :company_id,
    options_from_collection_for_select(Company.active.order(:name), :id, :name, params[:company_id]),
    include_blank: "Todas as empresas",
    data: { "project-selector-target": "companySelect", action: "change->project-selector#loadProjects" } %>

  <%= select_tag :project_id,
    options_from_collection_for_select(Project.all.order(:name), :id, :name, params[:project_id]),
    include_blank: "Todos os projetos",
    data: { "project-selector-target": "projectSelect" } %>
</div>
```

O `loadProjects()` do controller já popula o select de projetos baseado na empresa selecionada.

### ⚠️ Formulário de filtros: método GET, sem CSRF token

Filtros devem usar `method: :get` para que a URL reflita os parâmetros (bookmarkable, Turbo Frame compatível):

```erb
<%= form_with url: tasks_path, method: :get, data: { turbo_frame: "_top" } do |f| %>
  ...
<% end %>
```

Não use `method: :post` para filtros.

### ⚠️ Turbo Frames NÃO são necessários nesta story

A arquitetura DM-006 prevê Turbo Frames para Epic 6 (DA-050), mas **esta story (6.1) usa filtro com GET simples** — o form submete e a página recarrega com os filtros aplicados. A integração com Turbo Frames é responsabilidade da Story 6.4 (`criar-stimulus-controller-para-filtros-com-turbo-frames`).

**Nesta story:** form GET simples + redirect/render normal. Sem Turbo Frames ainda.

### ⚠️ DARK THEME obrigatório

Consistência visual com Epic 5. Use:
```
Selects:    bg-gray-700 border-gray-600 text-white rounded-md
Labels:     text-gray-400 text-sm
Container:  bg-gray-800 border border-gray-700 rounded-lg p-4 mb-6
Botão:      bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md
Link limpar: text-gray-400 hover:text-white
```

### ⚠️ Scopes `by_company` e `by_project` já existem no modelo Task

```ruby
# app/models/task.rb — NÃO recriar
scope :by_company, ->(company_id) { where(company_id:) }
scope :by_project, ->(project_id) { where(project_id:) }
```

---

## Contexto Técnico

### Stack atual do projeto

- **Rails** 8.1.2, **Ruby** 3.x, **PostgreSQL**
- **CSS:** Tailwind CSS (dark theme: `bg-gray-900`, `bg-gray-800`, `text-white`)
- **JS:** Turbo Rails + Stimulus Rails
- **ViewComponent:** 3.24.0 (já instalada)
- **Testes:** RSpec + FactoryBot + Faker

### Estado atual de `app/controllers/tasks_controller.rb`

```ruby
class TasksController < ApplicationController
  before_action :require_authentication
  before_action :set_task, only: [ :edit, :update, :destroy ]

  def index
    @tasks = Task
      .includes(:company, :project, :task_items)
      .where(start_date: Date.current.all_month)
      .order(start_date: :desc, created_at: :desc)

    @daily_total = calculate_daily_total
    @company_monthly_totals = calculate_company_totals
  end

  # ... create, edit, update, destroy (com Turbo Stream responses)

  private

  def calculate_daily_total
    TaskItem.joins(:task).where(tasks: { start_date: Date.current }).sum(:hours_worked)
  end

  def calculate_company_totals
    Company
      .joins(tasks: :task_items)
      .where(tasks: { start_date: Date.current.all_month })
      .group("companies.id", "companies.name", "companies.hourly_rate")
      .select("companies.id", "companies.name", "companies.hourly_rate",
              "SUM(task_items.hours_worked) as total_hours")
      .order("companies.name")
  end
end
```

### Rotas atuais (`config/routes.rb`)

```ruby
resources :tasks, only: [ :index, :new, :create, :edit, :update, :destroy ] do
  resources :task_items, only: [ :create, :update, :destroy ]
end
resources :projects, only: [ :index, :new, :create, :edit, :update, :destroy ] do
  collection do
    get :projects, to: "projects#projects_json", defaults: { format: :json }
  end
end
```

> A rota `/projects/projects.json?company_id=X` já existe para o `project_selector_controller.js`.

### Stimulus controller existente para projetos dinâmicos

```javascript
// app/javascript/controllers/project_selector_controller.js
// targets: ["companySelect", "projectSelect"]
// loadProjects(): fetch /projects/projects.json?company_id=X → popula projectSelect
```

### Componentes existentes (Epic 5)

```
app/components/
  task_card_component.rb/.html.erb           # ✅ card da task na tabela
  status_badge_component.rb/.html.erb        # ✅ badge de status
  daily_total_component.rb/.html.erb         # ✅ total do dia
  company_monthly_total_component.rb/.html.erb  # ✅ totais por empresa
```

### Scopes existentes em `app/models/task.rb`

```ruby
scope :by_status, ->(status) { where(status:) }
scope :by_company, ->(company_id) { where(company_id:) }
scope :by_project, ->(project_id) { where(project_id:) }
```

### Factories disponíveis

```ruby
# factory :company — spec/factories/companies.rb
# factory :project — association :company
# factory :task — association :company, :project; traits: :pending, :completed, :delivered
# factory :task_item — association :task; traits: :completed, :long_duration, :short_duration
```

### Estado atual de `app/views/tasks/index.html.erb`

```erb
<div class="max-w-7xl mx-auto">
  <div class="flex items-center justify-between mb-6">
    <h1 class="text-2xl font-bold text-white">Tarefas do Mês</h1>
    <%= link_to "Nova Tarefa", new_task_path, class: "..." %>
  </div>

  <%= render "tasks/daily_total", daily_total: @daily_total %>
  <%= render "tasks/company_monthly_totals", totals: @company_monthly_totals %>

  <div class="bg-gray-800 shadow-sm rounded-lg border border-gray-700 overflow-hidden">
    ...tabela com TaskCardComponent...
  </div>
</div>
```

---

## Tasks / Subtasks

### 1. Adicionar variáveis de filtro ao `TasksController#index`

- [x] Abrir `app/controllers/tasks_controller.rb`
- [x] Na action `index`, após a query base de `@tasks`, adicionar filtros opcionais:
  ```ruby
  def index
    @tasks = Task
      .includes(:company, :project, :task_items)
      .where(start_date: Date.current.all_month)
      .order(start_date: :desc, created_at: :desc)

    @tasks = @tasks.by_company(params[:company_id]) if params[:company_id].present?
    @tasks = @tasks.by_project(params[:project_id]) if params[:project_id].present?

    @daily_total = calculate_daily_total
    @company_monthly_totals = calculate_company_totals(@tasks)

    # Para repopular os selects com as opções corretas
    @companies = Company.active.order(:name)
    @projects = params[:company_id].present? ?
      Project.where(company_id: params[:company_id]).order(:name) :
      Project.all.order(:name)
  end
  ```
- [x] Modificar `calculate_company_totals` para aceitar parâmetro opcional:
  ```ruby
  def calculate_company_totals(filtered_tasks = nil)
    base_ids = (filtered_tasks || Task.where(start_date: Date.current.all_month)).select(:id)
    Company
      .joins(tasks: :task_items)
      .where(tasks: { id: base_ids })
      .group("companies.id", "companies.name", "companies.hourly_rate")
      .select("companies.id", "companies.name", "companies.hourly_rate",
              "SUM(task_items.hours_worked) as total_hours")
      .order("companies.name")
  end
  ```
- [x] **Não modificar** os Turbo Stream responses de `create`/`update`/`destroy` — eles chamam `calculate_company_totals` sem parâmetro (comportamento correto: mês completo sem filtro)

### 2. Criar partial `app/views/tasks/_filters.html.erb`

- [x] Criar `app/views/tasks/_filters.html.erb` com o formulário de filtros:
  ```erb
  <div class="bg-gray-800 border border-gray-700 rounded-lg p-4 mb-6" data-controller="project-selector">
    <%= form_with url: tasks_path, method: :get, class: "flex flex-wrap gap-4 items-end" do |f| %>
      <div>
        <label class="block text-gray-400 text-sm mb-1">Empresa</label>
        <%= select_tag :company_id,
          options_from_collection_for_select(@companies, :id, :name, params[:company_id]),
          include_blank: "Todas as empresas",
          class: "bg-gray-700 border border-gray-600 text-white rounded-md px-3 py-2 text-sm",
          data: { "project-selector-target": "companySelect",
                  action: "change->project-selector#loadProjects" } %>
      </div>

      <div>
        <label class="block text-gray-400 text-sm mb-1">Projeto</label>
        <%= select_tag :project_id,
          options_from_collection_for_select(@projects, :id, :name, params[:project_id]),
          include_blank: "Todos os projetos",
          class: "bg-gray-700 border border-gray-600 text-white rounded-md px-3 py-2 text-sm",
          data: { "project-selector-target": "projectSelect" } %>
      </div>

      <div class="flex gap-2">
        <%= f.submit "Filtrar",
          class: "bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium cursor-pointer" %>
        <% if params[:company_id].present? || params[:project_id].present? %>
          <%= link_to "Limpar", tasks_path,
            class: "text-gray-400 hover:text-white px-4 py-2 rounded-md text-sm border border-gray-600 hover:border-gray-400" %>
        <% end %>
      </div>
    <% end %>
  </div>
  ```

### 3. Integrar filtros em `app/views/tasks/index.html.erb`

- [x] Abrir `app/views/tasks/index.html.erb`
- [x] Adicionar render do partial de filtros após o header (antes dos totalizadores):
  ```erb
  <%= render "tasks/filters" %>
  ```

### 4. Escrever specs no `tasks_controller_spec.rb`

- [x] Adicionar dentro do `describe "GET #index"` existente:

  ```ruby
  context "com filtro de empresa" do
    let(:company1) { create(:company) }
    let(:company2) { create(:company) }
    let!(:task1) { create(:task, company: company1, start_date: Date.current) }
    let!(:task2) { create(:task, company: company2, start_date: Date.current) }

    it "filtra tasks pela empresa selecionada" do
      get :index, params: { company_id: company1.id }
      expect(assigns(:tasks)).to include(task1)
      expect(assigns(:tasks)).not_to include(task2)
    end
  end

  context "com filtro de projeto" do
    let(:company) { create(:company) }
    let(:project1) { create(:project, company:) }
    let(:project2) { create(:project, company:) }
    let!(:task1) { create(:task, company:, project: project1, start_date: Date.current) }
    let!(:task2) { create(:task, company:, project: project2, start_date: Date.current) }

    it "filtra tasks pelo projeto selecionado" do
      get :index, params: { project_id: project1.id }
      expect(assigns(:tasks)).to include(task1)
      expect(assigns(:tasks)).not_to include(task2)
    end
  end

  context "com filtros combinados (empresa + projeto)" do
    let(:company) { create(:company) }
    let(:project) { create(:project, company:) }
    let(:other_project) { create(:project, company:) }
    let!(:task1) { create(:task, company:, project:, start_date: Date.current) }
    let!(:task2) { create(:task, company:, project: other_project, start_date: Date.current) }

    it "aplica ambos os filtros simultaneamente" do
      get :index, params: { company_id: company.id, project_id: project.id }
      expect(assigns(:tasks)).to include(task1)
      expect(assigns(:tasks)).not_to include(task2)
    end
  end

  context "sem filtros" do
    it "retorna todas as tasks do mês" do
      get :index
      expect(assigns(:tasks)).to be_present
    end
  end
  ```

### 5. Rodar todos os testes

- [x] `bundle exec rspec spec/controllers/tasks_controller_spec.rb` — 48/50 passando (2 failures pré-existentes não relacionados à story)
- [x] `bundle exec rspec spec/models/task_spec.rb` — scopes by_company e by_project (existentes, não modificados)
- [x] `bundle exec rspec spec/` — 111 failures pré-existentes confirmados via git stash; zero regressões introduzidas

---

## Contexto de Integrações

### O que já existe e deve ser preservado

| Arquivo | Status | Impacto |
|---------|--------|---------|
| `app/controllers/tasks_controller.rb` | ✅ Existente | Adicionar filtros no index + modificar calculate_company_totals |
| `app/views/tasks/index.html.erb` | ✅ Existente | Adicionar render partial de filtros |
| `app/views/tasks/_daily_total.html.erb` | ✅ Existente | Não modificar |
| `app/views/tasks/_company_monthly_totals.html.erb` | ✅ Existente | Não modificar |
| `app/javascript/controllers/project_selector_controller.js` | ✅ Existente | Reutilizar — não modificar |
| `app/models/task.rb` (scopes) | ✅ Existente | Não recriar scopes — usar os existentes |
| `spec/controllers/tasks_controller_spec.rb` | ✅ 43 examples | Adicionar specs de filtros |

### O que NÃO deve ser criado nesta story

- Turbo Frames para atualização parcial (Story 6.4)
- Filtros por status e data/período (Story 6.2)
- Recálculo de totalizadores via filtro dinâmico (Story 6.3 — embora os totalizadores já recalculem com as tasks filtradas, a integração full com Turbo Frame fica na 6.3)
- Novo Stimulus controller para filtros (Story 6.4)

### Dependências satisfeitas do Epic 5

| Componente | Status |
|-----------|--------|
| `@tasks` com eager loading no index | ✅ Story 5.1 |
| `TaskCardComponent` para renderização | ✅ Story 5.2 |
| `DailyTotalComponent` | ✅ Story 5.3 |
| `CompanyMonthlyTotalComponent` | ✅ Story 5.4 |
| Turbo Streams no controller | ✅ Story 5.5 |
| Partials `_daily_total` e `_company_monthly_totals` | ✅ Story 5.5 |

---

## Dev Agent Record

### File List

- `app/controllers/tasks_controller.rb` — filtros by_company/by_project no index; calculate_company_totals aceita filtered_tasks opcional; @companies e @projects para selects
- `app/views/tasks/_filters.html.erb` — CRIADO: formulário GET com selects de empresa/projeto, dark theme, reutiliza project-selector Stimulus controller
- `app/views/tasks/index.html.erb` — adicionado `render "tasks/filters"` antes dos totalizadores
- `spec/controllers/tasks_controller_spec.rb` — 7 novos specs: @companies, @projects, filtro por empresa, filtro por projeto, filtros combinados, sem filtros + projetos filtrados por empresa

### Completion Notes

Implementados todos os 4 subtasks da story 6.1:
- `TasksController#index` aplica `by_company` e `by_project` condicionalmente; `@companies` e `@projects` populam os selects
- `calculate_company_totals` refatorado para aceitar `filtered_tasks` opcional — Turbo Stream de create/update/destroy não afetados (chamam sem argumento = mês completo)
- `_filters.html.erb` criado com dark theme consistente; reutiliza `project-selector` Stimulus controller existente; botão "Limpar" condicional
- 7 specs novos passando 100%; 2 failures pré-existentes confirmados via git stash (não introduzidos por esta story)
- URL reflete filtros (`/tasks?company_id=1&project_id=2`) — AC6 ✅

### Senior Developer Review (AI)

**Outcome:** Changes Requested
**Data:** 2026-04-01
**Revisores:** Blind Hunter + Edge Case Hunter + Acceptance Auditor

#### Action Items

- [x] [Review][Decision] `calculate_company_totals` recebe `@tasks` com `includes`, `.select(:id)` pode conflitar — resolvido: usar `unscope(:includes).select(:id)` em ambos os métodos [`app/controllers/tasks_controller.rb:103`]
- [x] [Review][Patch] HTML inválido no label "Projeto" — false positive: arquivo real não contém `>` duplicado [`app/views/tasks/_filters.html.erb:14`]
- [x] [Review][Patch] `params[:company_id]` e `params[:project_id]` coercidos para inteiro via `.to_i` [`app/controllers/tasks_controller.rb:11-12`]
- [x] [Review][Patch] `@daily_total` agora respeita filtros — `calculate_daily_total(filtered_tasks)` refatorado com `unscope(:includes).where(start_date: Date.current)` [`app/controllers/tasks_controller.rb:92`]
- [x] [Review][Patch] `Project.all` substituído por `Project.joins(:company).merge(Company.active)` [`app/controllers/tasks_controller.rb:23`]
- [x] [Review][Defer] Seleção prévia de projeto não preservada após troca de empresa via Stimulus — pré-existente no project_selector_controller.js [`app/javascript/controllers/project_selector_controller.js`] — deferred, pre-existing
- [x] [Review][Defer] Empresa com tasks mas sem task_items excluída de `@company_monthly_totals` — comportamento pré-existente do INNER JOIN [`app/controllers/tasks_controller.rb`] — deferred, pre-existing
- [x] [Review][Defer] Endpoint `/projects/projects.json` sem autenticação — pré-existente, fora do escopo desta story [`app/controllers/projects_controller.rb`] — deferred, pre-existing

### Change Log

- 2026-03-31: Story 6.1 criada — filtros por empresa e projeto
- 2026-03-31: Story 6.1 implementada — filtros GET por empresa/projeto, partial _filters, 7 specs adicionados
- 2026-04-01: Code review — 1 decision_needed, 4 patches, 3 deferred, 2 dismissed
- 2026-04-01: Review follow-ups resolvidos — 5/5 action items fechados; 53/53 specs controller passando
