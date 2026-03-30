# Story 5.4: Implementar Totalizadores por Empresa no Mês

**Status:** done
**Domínio:** DM-005-visualizacao-totalizadores
**Data:** 2026-03-30
**Epic:** DM-005 — Visualização & Totalizadores
**Story ID:** 5.4
**Story Key:** 5-4-implementar-totalizadores-por-empresa-no-mes

---

## Story

**Como** Igor,
**Quero** ver o total de horas trabalhadas e o valor monetário por empresa no mês atual,
**Para que** eu saiba exatamente quanto trabalhei para cada cliente e quanto vou receber.

---

## Acceptance Criteria

**Given** que estou autenticado e acesso `/tasks`

**When** a página carrega

**Then**
1. Uma seção "Totais do Mês por Empresa" exibe uma linha por empresa com tasks no mês atual
2. Cada linha mostra: nome da empresa, total de horas (formato `"X.XX h"`), valor total (formato `"R$ X.XXX,XX"`)
3. O cálculo de horas usa `SUM(task_items.hours_worked)` agrupado por empresa
4. O cálculo de valor usa `SUM(task_items.hours_worked) * company.hourly_rate`
5. Se não houver tasks no mês, a seção não é exibida (ou exibe mensagem "Sem registros no mês")
6. Existe `app/components/company_monthly_total_component.rb` herdando `ViewComponent::Base`
7. Existe `app/components/company_monthly_total_component.html.erb` com dark theme consistente
8. O componente é renderizado em `tasks/index.html.erb` após o `DailyTotalComponent`
9. `bundle exec rspec spec/components/company_monthly_total_component_spec.rb` passa 100%
10. Todos os testes existentes (≥ 166 + specs da Story 5.3) continuam passando

---

## CRITICAL GUARDRAILS — Leia antes de implementar

### ⚠️ MODELO CORRETO: `Task` + `TaskItem` + `Company`, NÃO `TimeEntry`

Não existe modelo `TimeEntry` no projeto. Os dados de horas ficam em `TaskItem#hours_worked`.
A associação é: `Company → Tasks → TaskItems`.

### ⚠️ Query de agregação por empresa (DA-043 da arquitetura)

```ruby
# app/controllers/tasks_controller.rb — action index
@company_monthly_totals = Task
  .where(start_date: Date.current.all_month)
  .joins(:company, :task_items)
  .group('companies.id', 'companies.name', 'companies.hourly_rate')
  .select(
    'companies.id',
    'companies.name',
    'companies.hourly_rate',
    'SUM(task_items.hours_worked) as total_hours'
  )
```

### ⚠️ Cálculo de valor no componente, não na query

O valor monetário é calculado no componente a partir de `total_hours * hourly_rate`:

```ruby
# app/components/company_monthly_total_component.rb
def formatted_value(row)
  value = row.total_hours.to_f * row.hourly_rate.to_f
  "R$ #{format('%.2f', value).gsub('.', ',')}"
end
```

### ⚠️ `hourly_rate` está em `companies`, NÃO em `tasks` ou `task_items`

A taxa horária pertence à empresa: `companies.hourly_rate` (decimal).

### ⚠️ SEM Turbo Streams nesta story

Turbo Streams para atualização em tempo real são Story 5.5. Esta story exibe os totais **server-rendered**.

### ⚠️ Não alterar a query de `@tasks` existente

Apenas **adicione** `@company_monthly_totals` como linha separada no controller:

```ruby
def index
  @tasks = Task
    .includes(:company, :project, :task_items)
    .where(start_date: Date.current.all_month)
    .order(start_date: :desc, created_at: :desc)

  @daily_total = TaskItem
    .joins(:task)
    .where(tasks: { start_date: Date.current })
    .sum(:hours_worked)

  @company_monthly_totals = Task
    .where(start_date: Date.current.all_month)
    .joins(:company, :task_items)
    .group('companies.id', 'companies.name', 'companies.hourly_rate')
    .select(
      'companies.id',
      'companies.name',
      'companies.hourly_rate',
      'SUM(task_items.hours_worked) as total_hours'
    )
end
```

### ⚠️ DARK THEME obrigatório

O projeto usa dark theme. Use estas classes:
```
Card background:  bg-gray-800
Border:           border border-gray-700
Cabeçalho:        text-gray-400 text-xs font-medium uppercase tracking-wider
Valor principal:  text-white font-bold
Valor secundário: text-gray-300
Container:        rounded-lg px-6 py-4
```

### ⚠️ ViewComponent: gem já instalada (3.24.0)

A gem `view_component` já está instalada desde a Story 5.2. O RSpec helpers também já estão em `spec/rails_helper.rb`. **Não precisa instalar nem reconfigurar.**

### ⚠️ Dependência da Story 5.3

Esta story depende que a Story 5.3 esteja `done` (o `@daily_total` já calculado no controller). Certifique-se que 5.3 está implementada antes de iniciar.

---

## Contexto Técnico

### Stack atual do projeto

- **Rails** 8.1.2, **Ruby** 3.x, **PostgreSQL**
- **CSS:** Tailwind CSS (dark theme: `bg-gray-900`, `bg-gray-800`, `text-white`)
- **JS:** Turbo Rails + Stimulus Rails
- **ViewComponent:** 3.24.0 (já instalada)
- **Testes:** RSpec + FactoryBot + Faker

### Estrutura de componentes existente

```
app/components/
  status_badge_component.rb         # ✅ existente (Story 5.2)
  status_badge_component.html.erb   # ✅ existente (Story 5.2)
  task_card_component.rb            # ✅ existente (Story 5.2)
  task_card_component.html.erb      # ✅ existente (Story 5.2)
  daily_total_component.rb          # ✅ existente (Story 5.3)
  daily_total_component.html.erb    # ✅ existente (Story 5.3)

spec/components/
  status_badge_component_spec.rb    # ✅ existente
  task_card_component_spec.rb       # ✅ existente
  daily_total_component_spec.rb     # ✅ existente (Story 5.3)
```

**Novo nesta story:**
```
app/components/
  company_monthly_total_component.rb         # CRIAR
  company_monthly_total_component.html.erb   # CRIAR

spec/components/
  company_monthly_total_component_spec.rb    # CRIAR
```

### Schema relevante

```
companies:
  id, name, hourly_rate (decimal), ...

tasks:
  id, name, company_id, project_id, start_date (date), status,
  estimated_hours (decimal), validated_hours (decimal), ...

task_items:
  id, task_id, start_time (time), end_time (time),
  status, hours_worked (decimal, calculado via before_save)
```

### Factories disponíveis

```ruby
# factory :company — spec/factories/companies.rb
#   - hourly_rate: Faker::Number.decimal (padrão)

# factory :task — spec/factories/tasks.rb
#   - association :company
#   - association :project
#   - traits: :pending, :completed, :delivered

# factory :task_item — spec/factories/task_items.rb
#   - association :task
#   - start_time / end_time (hours_worked calculado)
#   - traits: :completed, :long_duration, :short_duration
```

---

## Tasks / Subtasks

### 1. Atualizar `TasksController#index` para calcular `@company_monthly_totals`

- [x] Abrir `app/controllers/tasks_controller.rb`
- [x] Adicionar a query de agregação após `@daily_total` (ver query acima)
- [x] **Não modificar** as queries de `@tasks` e `@daily_total` existentes

### 2. Criar `CompanyMonthlyTotalComponent`

- [x] Criar `app/components/company_monthly_total_component.rb`:

```ruby
class CompanyMonthlyTotalComponent < ViewComponent::Base
  def initialize(totals:)
    @totals = totals
  end

  def formatted_hours(row)
    "#{format('%.2f', row.total_hours.to_f)} h"
  end

  def formatted_value(row)
    value = row.total_hours.to_f * row.hourly_rate.to_f
    "R$ #{format('%.2f', value).gsub('.', ',')}"
  end
end
```

- [x] Criar `app/components/company_monthly_total_component.html.erb`:

```erb
<div class="bg-gray-800 border border-gray-700 rounded-lg px-6 py-4">
  <p class="text-xs font-medium text-gray-400 uppercase tracking-wider mb-3">Totais do Mês por Empresa</p>
  <% if @totals.any? %>
    <div class="space-y-2">
      <% @totals.each do |row| %>
        <div class="flex items-center justify-between">
          <span class="text-white font-medium"><%= row.name %></span>
          <div class="flex gap-4 text-sm">
            <span class="text-gray-300"><%= formatted_hours(row) %></span>
            <span class="text-white font-bold"><%= formatted_value(row) %></span>
          </div>
        </div>
      <% end %>
    </div>
  <% else %>
    <p class="text-gray-400 text-sm">Sem registros no mês</p>
  <% end %>
</div>
```

### 3. Integrar componente em `tasks/index.html.erb`

- [x] Abrir `app/views/tasks/index.html.erb`
- [x] Adicionar **após** o `DailyTotalComponent`:

```erb
<div class="mb-6">
  <%= render CompanyMonthlyTotalComponent.new(totals: @company_monthly_totals) %>
</div>
```

### 4. Escrever specs do componente

- [x] Criar `spec/components/company_monthly_total_component_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe CompanyMonthlyTotalComponent, type: :component do
  let(:company) { create(:company, name: "Acme Corp", hourly_rate: 45.0) }

  def build_row(name:, hourly_rate:, total_hours:)
    OpenStruct.new(name: name, hourly_rate: hourly_rate, total_hours: total_hours)
  end

  context "com dados" do
    let(:totals) { [build_row(name: "Acme Corp", hourly_rate: 45.0, total_hours: 10.0)] }

    it "exibe o nome da empresa" do
      render_inline(described_class.new(totals: totals))
      expect(page).to have_text("Acme Corp")
    end

    it "exibe horas formatadas" do
      render_inline(described_class.new(totals: totals))
      expect(page).to have_text("10.00 h")
    end

    it "exibe valor calculado corretamente (10h * R$45 = R$450)" do
      render_inline(described_class.new(totals: totals))
      expect(page).to have_text("R$ 450,00")
    end

    it "exibe o header 'Totais do Mês por Empresa'" do
      render_inline(described_class.new(totals: totals))
      expect(page).to have_text("Totais do Mês por Empresa")
    end
  end

  context "sem dados" do
    it "exibe mensagem de sem registros" do
      render_inline(described_class.new(totals: []))
      expect(page).to have_text("Sem registros no mês")
    end
  end

  describe "#formatted_hours" do
    it "formata 1.5 como '1.50 h'" do
      component = described_class.new(totals: [])
      row = build_row(name: "X", hourly_rate: 0, total_hours: 1.5)
      expect(component.formatted_hours(row)).to eq("1.50 h")
    end
  end

  describe "#formatted_value" do
    it "calcula 8h * R$50 = R$ 400,00" do
      component = described_class.new(totals: [])
      row = build_row(name: "X", hourly_rate: 50.0, total_hours: 8.0)
      expect(component.formatted_value(row)).to eq("R$ 400,00")
    end
  end
end
```

### 5. Rodar todos os testes

- [x] `bundle exec rspec spec/components/company_monthly_total_component_spec.rb` — 11/11 passando
- [x] `bundle exec rspec spec/components/` — 41/41 passando
- [x] `bundle exec rspec spec/controllers/tasks_controller_spec.rb` — sem regressões (falhas pré-existentes confirmadas)
- [x] `bundle exec rspec spec/models/` — sem regressões (falhas pré-existentes confirmadas)

---

## Contexto de Integrações

### O que já existe e deve ser preservado

| Arquivo | Status | Impacto |
|---------|--------|---------|
| `app/controllers/tasks_controller.rb` | ✅ Existente | Adicionar `@company_monthly_totals` na action index |
| `app/views/tasks/index.html.erb` | ✅ Existente | Adicionar render CompanyMonthlyTotalComponent |
| `app/components/daily_total_component.rb` | ✅ Existente (Story 5.3) | Não modificar |
| `app/components/task_card_component.rb` | ✅ Existente | Não modificar |
| `app/models/task.rb` | ✅ Existente | Não modificar |
| `app/models/task_item.rb` | ✅ Existente | Não modificar |
| `app/models/company.rb` | ✅ Existente | Não modificar |

### O que NÃO deve ser criado nesta story

- Turbo Streams para atualização em tempo real (Story 5.5)
- Filtros dinâmicos (Domínio DM-006)
- Links de editar/deletar tasks (Stories 7.1 e 7.2)

---

## Dev Agent Record

### File List

- `app/controllers/tasks_controller.rb` — adicionar `@company_monthly_totals` na action index
- `app/components/company_monthly_total_component.rb` — CRIAR
- `app/components/company_monthly_total_component.html.erb` — CRIAR
- `app/views/tasks/index.html.erb` — adicionar render CompanyMonthlyTotalComponent
- `spec/components/company_monthly_total_component_spec.rb` — CRIAR

### Completion Notes

Implementado em 2026-03-30 por Dev Agent (Amelia).

- **Task 1**: Query `@company_monthly_totals` adicionada em `TasksController#index` usando JOIN em `companies` e `task_items`, GROUP BY empresa, SUM de `hours_worked`. Queries `@tasks` e `@daily_total` preservadas sem modificação.
- **Task 2**: `CompanyMonthlyTotalComponent` criado. **Decisão crítica**: usou `sprintf('%.2f', ...)` ao invés de `format()` da spec (guardrail do projeto — `ViewComponent::Base` sobrescreve `format()`).
- **Task 3**: Componente integrado na view após `DailyTotalComponent`.
- **Task 4**: 11 specs criadas. Fix necessário: adicionado `require "ostruct"` pois Ruby 3.x não carrega `OpenStruct` automaticamente.
- **Task 5**: 11/11 specs do componente passando. 41/41 specs de componentes passando. 2 falhas pré-existentes em `tasks_controller_spec.rb` e `task_spec.rb` confirmadas como anteriores a esta story.

### Change Log

- 2026-03-30: Story 5.4 reescrita — corrigido uso de TimeEntry para Task/TaskItem/Company conforme arquitetura DM-005
- 2026-03-30: Story 5.4 implementada — CompanyMonthlyTotalComponent criado, integrado na view, 11 specs passando
- 2026-03-30: Ajustes pós-QA — HIGH-001: separador de milhar em formatted_value; MEDIUM-002: removed unused let(:company); MEDIUM-003: controller spec cobre @company_monthly_totals; LOW-002: ordenação por companies.name adicionada
- 2026-03-30: Fix crítico pós-Playwright — query migrada de Task.joins(:company) para Company.joins(tasks: :task_items); Task#after_find disparava MissingAttributeError ao iterar resultados com SELECT parcial
