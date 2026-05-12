# Story 6.2: Implementar Filtros por Status e Data/Período

**Status:** done
**Domínio:** DM-006-filtros-dinamicos
**Data:** 2026-04-03
**Epic:** DM-006 — Filtros Dinâmicos
**Story ID:** 6.2
**Story Key:** 6-2-implementar-filtros-por-status-e-data-periodo

---

## Story

**Como** Igor,
**Quero** filtrar a listagem de tarefas por status e por período de datas,
**Para que** eu analise dados históricos e isole tarefas por estado de progresso.

---

## Acceptance Criteria

**Given** que estou autenticado e acesso `/tasks`

**When** a página carrega

**Then**
1. O formulário de filtros (partial `_filters.html.erb`) exibe um select de "Status" com opções: "Todos os status", "Pendente", "Concluído", "Entregue"
2. O formulário exibe um select de "Período" com presets: "Mês atual", "Mês anterior", "Últimos 7 dias", "Semana atual" e opção "Personalizado"
3. Quando "Personalizado" é selecionado, dois campos de data (`start_date` e `end_date`) ficam visíveis
4. Ao aplicar filtro de status, a listagem filtra: `@tasks.where(status: params[:status])`
5. Ao aplicar filtro de período preset, a listagem filtra por `start_date` usando o range correspondente
6. Ao aplicar período personalizado, filtra por `start_date: params[:start_date]..params[:end_date]`
7. Filtros de status e período são combináveis entre si e com os filtros da Story 6.1 (empresa + projeto)
8. A URL reflete todos os filtros: `/tasks?company_id=1&status=pending&period=last_7_days`
9. O botão "Limpar" aparece quando qualquer filtro está ativo (empresa, projeto, status ou período)
10. Os totalizadores recalculam sobre as tasks filtradas
11. Filtros aplicam em < 1s (NFR4)
12. `bundle exec rspec spec/controllers/tasks_controller_spec.rb` passa 100%
13. Todos os testes existentes continuam passando

---

## CRITICAL GUARDRAILS — Leia antes de implementar

### ⚠️ MODELO CORRETO: `Task`, NÃO `TimeEntry`

Não existe modelo `TimeEntry`. O filtro de status usa o enum do modelo `Task`:
```ruby
enum :status, { pending: "pending", completed: "completed", delivered: "delivered" }
```

Status válidos: `pending`, `completed`, `delivered`. **Não existe `reopened`.**

### ⚠️ Filtro de período age sobre `tasks.start_date`, NÃO sobre `task_items`

A coluna de data está em `tasks.start_date` (tipo `date`). O filtro de período substitui o filtro padrão de mês atual:

```ruby
# Padrão atual (sem filtro de período):
.where(start_date: Date.current.all_month)

# Com período selecionado — substitui o all_month:
.where(start_date: period_range)
```

### ⚠️ `period` substitui o filtro de mês atual — não acumula

O controller atual filtra `.where(start_date: Date.current.all_month)` por padrão. Quando um `period` é selecionado, esse range deve ser **substituído** pelo período escolhido, não adicionado:

```ruby
def index
  period_range = resolve_period_range   # retorna range ou Date.current.all_month

  @tasks = Task
    .includes(:company, :project, :task_items)
    .where(start_date: period_range)
    .order(start_date: :desc, created_at: :desc)

  company_id = params[:company_id].present? ? params[:company_id].to_i : nil
  project_id = params[:project_id].present? ? params[:project_id].to_i : nil

  @tasks = @tasks.by_company(company_id) if company_id
  @tasks = @tasks.by_project(project_id) if project_id
  @tasks = @tasks.where(status: params[:status]) if params[:status].present?

  @daily_total = calculate_daily_total(@tasks)
  @company_monthly_totals = calculate_company_totals(@tasks)

  @companies = Company.active.order(:name)
  @projects = company_id ?
    Project.where(company_id: company_id).order(:name) :
    Project.joins(:company).merge(Company.active).order(:name)
end

private

def resolve_period_range
  case params[:period]
  when "current_month"  then Date.current.all_month
  when "last_month"     then 1.month.ago.all_month
  when "last_7_days"    then 7.days.ago.to_date..Date.current
  when "current_week"   then Date.current.all_week
  when "custom"
    start_d = params[:start_date].present? ? Date.parse(params[:start_date]) rescue nil : nil
    end_d   = params[:end_date].present?   ? Date.parse(params[:end_date])   rescue nil : nil
    (start_d && end_d) ? start_d..end_d : Date.current.all_month
  else
    Date.current.all_month   # default
  end
end
```

### ⚠️ `Date.parse` com rescue — evitar crash por data inválida

Datas vindas de params podem ser inválidas. Use `rescue nil` e fallback para o mês atual se parse falhar.

### ⚠️ Período personalizado: campos de data só aparecem com JS

O select de período tem opção "custom". Quando selecionado, dois `<input type="date">` devem aparecer. Isso requer Stimulus ou JS inline. **Use o Stimulus controller existente** (`filter_controller.js` — a ser criado na Story 6.4) ou um JS inline simples para esta story:

```erb
<%= select_tag :period, ...,
  data: { action: "change->period-toggle#toggle" } %>
```

**Alternativa mais simples sem novo controller:** mostrar os campos de data sempre, mas só aplicar se `params[:period] == "custom"`. O `resolve_period_range` já faz isso — campos visíveis o tempo todo é aceitável para esta story.

### ⚠️ Botão "Limpar" deve considerar todos os filtros ativos

Story 6.1 implementou o botão "Limpar" condicional apenas para `company_id` e `project_id`. Ampliar a condição:

```erb
<% if params[:company_id].present? || params[:project_id].present? ||
      params[:status].present? || params[:period].present? %>
  <%= link_to "Limpar", tasks_path, class: "..." %>
<% end %>
```

### ⚠️ `calculate_daily_total` usa `Date.current`, não o período filtrado

O total do dia **sempre** reflete o dia atual, independente do filtro de período. O método `calculate_daily_total(filtered_tasks)` já filtra por `start_date: Date.current` internamente — isso é correto e não deve mudar.

### ⚠️ `params[:status]` não precisa de `.to_i` — é string

Diferente de `company_id`/`project_id` (inteiros), o status é string (`"pending"`, `"completed"`, `"delivered"`). Não chamar `.to_i`.

---

## Contexto Técnico

### Stack atual do projeto

- **Rails** 8.1.2, **Ruby** 3.x, **PostgreSQL**
- **CSS:** Tailwind CSS (dark theme)
- **JS:** Turbo Rails + Stimulus Rails
- **Testes:** RSpec + FactoryBot + Faker

### Estado atual de `app/controllers/tasks_controller.rb` (após Story 6.1)

```ruby
def index
  @tasks = Task
    .includes(:company, :project, :task_items)
    .where(start_date: Date.current.all_month)   # ← será substituído por resolve_period_range
    .order(start_date: :desc, created_at: :desc)

  company_id = params[:company_id].present? ? params[:company_id].to_i : nil
  project_id = params[:project_id].present? ? params[:project_id].to_i : nil

  @tasks = @tasks.by_company(company_id) if company_id
  @tasks = @tasks.by_project(project_id) if project_id

  @daily_total = calculate_daily_total(@tasks)
  @company_monthly_totals = calculate_company_totals(@tasks)

  @companies = Company.active.order(:name)
  @projects = company_id ?
    Project.where(company_id: company_id).order(:name) :
    Project.joins(:company).merge(Company.active).order(:name)
end
```

### Estado atual de `app/views/tasks/_filters.html.erb` (após Story 6.1)

Contém selects de Empresa e Projeto com dark theme e botão Filtrar/Limpar. Esta story **adiciona** os selects de Status e Período ao mesmo formulário.

### Scopes existentes em `app/models/task.rb`

```ruby
scope :by_status, ->(status) { where(status:) }
scope :by_company, ->(company_id) { where(company_id:) }
scope :by_project, ->(project_id) { where(project_id:) }
```

> Pode usar `@tasks.by_status(params[:status])` ou `@tasks.where(status: params[:status])` — ambos equivalentes.

### Presets de período (DA-052 da arquitetura DM-006)

| Preset | Value param | Range |
|--------|-------------|-------|
| Mês atual | `current_month` | `Date.current.all_month` |
| Mês anterior | `last_month` | `1.month.ago.all_month` |
| Últimos 7 dias | `last_7_days` | `7.days.ago.to_date..Date.current` |
| Semana atual | `current_week` | `Date.current.all_week` |
| Personalizado | `custom` | `params[:start_date]..params[:end_date]` |

### Factories disponíveis

```ruby
# factory :task — traits: :pending, :completed, :delivered
# - start_date: Date.today (verificar factory para confirmar)
```

---

## Tasks / Subtasks

### 1. Adicionar método `resolve_period_range` ao `TasksController`

- [x] Abrir `app/controllers/tasks_controller.rb`
- [x] Substituir `.where(start_date: Date.current.all_month)` por `.where(start_date: resolve_period_range)` na action `index`
- [x] Adicionar filtro de status após os filtros existentes:
  ```ruby
  @tasks = @tasks.where(status: params[:status]) if params[:status].present?
  ```
- [x] Adicionar método privado `resolve_period_range` conforme guardrail acima

### 2. Atualizar partial `app/views/tasks/_filters.html.erb`

- [x] Adicionar select de Status:
  ```erb
  <div>
    <label class="block text-gray-400 text-sm mb-1">Status</label>
    <%= select_tag :status,
      options_for_select([
        ["Todos os status", ""],
        ["Pendente", "pending"],
        ["Concluído", "completed"],
        ["Entregue", "delivered"]
      ], params[:status]),
      class: "bg-gray-700 border border-gray-600 text-white rounded-md px-3 py-2 text-sm" %>
  </div>
  ```

- [x] Adicionar select de Período:
  ```erb
  <div>
    <label class="block text-gray-400 text-sm mb-1">Período</label>
    <%= select_tag :period,
      options_for_select([
        ["Mês atual", "current_month"],
        ["Mês anterior", "last_month"],
        ["Últimos 7 dias", "last_7_days"],
        ["Semana atual", "current_week"],
        ["Personalizado", "custom"]
      ], params[:period] || "current_month"),
      class: "bg-gray-700 border border-gray-600 text-white rounded-md px-3 py-2 text-sm" %>
  </div>
  ```

- [x] Adicionar campos de data para período personalizado (sempre visíveis, simples):
  ```erb
  <div>
    <label class="block text-gray-400 text-sm mb-1">De</label>
    <%= date_field_tag :start_date, params[:start_date],
      class: "bg-gray-700 border border-gray-600 text-white rounded-md px-3 py-2 text-sm" %>
  </div>
  <div>
    <label class="block text-gray-400 text-sm mb-1">Até</label>
    <%= date_field_tag :end_date, params[:end_date],
      class: "bg-gray-700 border border-gray-600 text-white rounded-md px-3 py-2 text-sm" %>
  </div>
  ```

- [x] Ampliar condição do botão "Limpar" para incluir `status` e `period`:
  ```erb
  <% if params[:company_id].present? || params[:project_id].present? ||
        params[:status].present? || (params[:period].present? && params[:period] != "current_month") %>
  ```

### 3. Escrever specs no `tasks_controller_spec.rb`

- [x] Adicionar dentro do `describe "GET #index"`:

  ```ruby
  context "com filtro de status" do
    let!(:task_pending)   { create(:task, :pending,   start_date: Date.current) }
    let!(:task_completed) { create(:task, :completed, start_date: Date.current) }

    it "filtra tasks pelo status selecionado" do
      get :index, params: { status: "pending" }
      expect(assigns(:tasks)).to include(task_pending)
      expect(assigns(:tasks)).not_to include(task_completed)
    end
  end

  context "com filtro de período last_7_days" do
    let!(:task_recent) { create(:task, start_date: 3.days.ago.to_date) }
    let!(:task_old)    { create(:task, start_date: 2.months.ago.to_date) }

    it "retorna apenas tasks dos últimos 7 dias" do
      get :index, params: { period: "last_7_days" }
      expect(assigns(:tasks)).to include(task_recent)
      expect(assigns(:tasks)).not_to include(task_old)
    end
  end

  context "com filtro de período personalizado" do
    let!(:task_in_range)  { create(:task, start_date: Date.new(2026, 3, 15)) }
    let!(:task_out_range) { create(:task, start_date: Date.new(2026, 1, 1)) }

    it "filtra tasks pelo range de datas informado" do
      get :index, params: { period: "custom", start_date: "2026-03-01", end_date: "2026-03-31" }
      expect(assigns(:tasks)).to include(task_in_range)
      expect(assigns(:tasks)).not_to include(task_out_range)
    end
  end

  context "com filtros combinados (status + empresa)" do
    let(:company) { create(:company) }
    let!(:task1) { create(:task, :pending, company:, start_date: Date.current) }
    let!(:task2) { create(:task, :completed, company:, start_date: Date.current) }

    it "aplica status e empresa simultaneamente" do
      get :index, params: { company_id: company.id, status: "pending" }
      expect(assigns(:tasks)).to include(task1)
      expect(assigns(:tasks)).not_to include(task2)
    end
  end
  ```

### 4. Rodar todos os testes

- [x] `bundle exec rspec spec/controllers/tasks_controller_spec.rb` — 57 examples, 0 failures ✅
- [x] `bundle exec rspec spec/` — 109 falhas pré-existentes confirmadas (mesmo número antes desta story) ✅

---

## Contexto de Integrações

### O que já existe e deve ser preservado

| Arquivo | Status | Impacto |
|---------|--------|---------|
| `app/controllers/tasks_controller.rb` | ✅ Story 6.1 | Substituir `all_month` por `resolve_period_range` + filtro status |
| `app/views/tasks/_filters.html.erb` | ✅ Story 6.1 | Adicionar selects de Status e Período + campos de data |
| `app/javascript/controllers/project_selector_controller.js` | ✅ Existente | Não modificar |
| `spec/controllers/tasks_controller_spec.rb` | ✅ 53 examples | Adicionar specs de status e período |

### O que NÃO deve ser criado nesta story

- Turbo Frames para atualização parcial (Story 6.4)
- Stimulus controller para filtros (Story 6.4)
- Recálculo dinâmico de totalizadores via AJAX (Story 6.3)
- Animações ou toggle JS para mostrar/ocultar campos de data (Story 6.4)

---

## Dev Agent Record

### File List

- `app/controllers/tasks_controller.rb` — substituir `all_month` por `resolve_period_range`; adicionar `@tasks.where(status:)` se status presente; adicionar método privado `resolve_period_range`
- `app/views/tasks/_filters.html.erb` — adicionados selects de Status e Período; campos `date_field_tag` para `start_date`/`end_date` (sempre visíveis); condição do botão Limpar ampliada
- `spec/controllers/tasks_controller_spec.rb` — +4 contexts: filtro de status, last_7_days, personalizado, combinado (status + empresa)

### Completion Notes

Implementado em 2026-04-03 por Amelia (bmad-dev-story):
- `resolve_period_range` substitui `Date.current.all_month` hardcoded — suporta 5 presets + custom com parse seguro
- Filtro de status via `params[:status].present?` guard — string, sem `.to_i` conforme guardrail
- Campos de data sempre visíveis (abordagem simples sem JS toggle — AC3 atendido, Story 6.4 adicionará toggle)
- Botão Limpar agora detecta `status` e `period` (exceto `current_month` que é default)
- 57 examples no controller spec, 0 failures; 109 falhas pré-existentes confirmadas sem regressão

### Change Log

- 2026-04-03: Story 6.2 criada — filtros por status e data/período
- 2026-04-03: Story 6.2 implementada — resolve_period_range, filtro status, UI parcial, specs +4 contexts
