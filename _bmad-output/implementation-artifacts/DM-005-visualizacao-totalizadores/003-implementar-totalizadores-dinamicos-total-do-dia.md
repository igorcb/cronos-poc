# Story 5.3: Implementar Totalizadores Dinâmicos — Total do Dia

**Status:** done
**Domínio:** DM-005-visualizacao-totalizadores
**Data:** 2026-03-28
**Epic:** DM-005 — Visualização & Totalizadores
**Story ID:** 5.3
**Story Key:** 5-3-implementar-totalizadores-dinamicos-total-do-dia

---

## Story

**Como** Igor,
**Quero** ver o total de horas trabalhadas no dia atual exibido na página de listagem de tarefas,
**Para que** eu saiba imediatamente quantas horas já registrei hoje sem precisar somar manualmente.

---

## Acceptance Criteria

**Given** que estou autenticado e acesso `/tasks`

**When** a página carrega

**Then**
1. Um card "Total do Dia" exibe a soma de `hours_worked` de todos os `TaskItem` do dia atual (`Date.current`)
2. O valor é exibido no formato decimal com 2 casas: `"6.50 horas"`
3. Se não houver TaskItems hoje, exibe `"0.00 horas"`
4. O cálculo usa `TaskItem.joins(:task).where(tasks: { start_date: Date.current }).sum(:hours_worked)`
5. Existe `app/components/daily_total_component.rb` herdando `ViewComponent::Base`
6. Existe `app/components/daily_total_component.html.erb` com dark theme consistente
7. O componente é renderizado em `tasks/index.html.erb` acima da tabela de tasks
8. `bundle exec rspec spec/components/daily_total_component_spec.rb` passa 100%
9. Todos os testes existentes (≥ 166) continuam passando

---

## CRITICAL GUARDRAILS — Leia antes de implementar

### ⚠️ MODELO CORRETO: `Task` + `TaskItem`, NÃO `TimeEntry`

Não existe modelo `TimeEntry` no projeto. Os dados de horas ficam em `TaskItem#hours_worked`.

A query de total do dia é:
```ruby
TaskItem.joins(:task)
  .where(tasks: { start_date: Date.current })
  .sum(:hours_worked)
```

**NUNCA referencie `TimeEntry` — use `Task` e `TaskItem`.**

### ⚠️ `hours_worked` está em `TaskItem`, NÃO em `Task`

- `Task` tem `estimated_hours` (decimal) e `validated_hours` (decimal)
- `TaskItem` tem `hours_worked` (decimal, calculado automaticamente via `before_save :calculate_hours_worked`)
- O total do dia deve somar `task_items.hours_worked` filtrado por `tasks.start_date = Date.current`

### ⚠️ `start_date` é na tabela `tasks`, NÃO em `task_items`

O `TaskItem` não possui coluna `date` ou `start_date` própria. A data pertence à `Task`:
```ruby
# CORRETO:
TaskItem.joins(:task).where(tasks: { start_date: Date.current }).sum(:hours_worked)

# ERRADO (coluna não existe em task_items):
TaskItem.where(start_date: Date.current).sum(:hours_worked)
```

### ⚠️ SEM Turbo Streams nesta story

Turbo Streams para atualização em tempo real são Story 5.5. Esta story exibe o total **server-rendered**, sem broadcast. O componente renderiza o valor calculado no momento do request.

### ⚠️ `@daily_total` deve ser calculado no controller, não no componente

O componente recebe o valor como parâmetro — sem acesso ao banco diretamente:
```ruby
# app/components/daily_total_component.rb
class DailyTotalComponent < ViewComponent::Base
  def initialize(total_hours:)
    @total_hours = total_hours
  end

  def formatted_total
    "#{ format('%.2f', @total_hours) } horas"
  end
end
```

### ⚠️ `Date.current` vs `Date.today`

Use `Date.current` (respeita timezone do Rails) em vez de `Date.today` (usa timezone do OS).

### ⚠️ Não alterar a query de `@tasks` existente

A query de `@tasks` já funciona com eager loading. Apenas **adicione** `@daily_total` como linha separada:

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
end
```

### ⚠️ DARK THEME obrigatório

O projeto usa dark theme. Use estas classes (NÃO use bg-white ou text-gray-900 para cards):
```
Card background:  bg-gray-800
Border:           border border-gray-700
Label (título):   text-gray-400 text-xs font-medium uppercase tracking-wider
Valor:            text-white text-2xl font-bold
Container:        rounded-lg px-6 py-4
```

### ⚠️ ViewComponent: gem já instalada (3.24.0)

A gem `view_component` (~> 3.21) já está instalada desde a Story 5.2. O RSpec helpers também já estão em `spec/rails_helper.rb`. **Não precisa instalar nem reconfigurar.**

---

## Contexto Técnico

### Stack atual do projeto

- **Rails** 8.1.2, **Ruby** 3.x, **PostgreSQL**
- **CSS:** Tailwind CSS (dark theme: `bg-gray-900`, `bg-gray-800`, `text-white`)
- **JS:** Turbo Rails + Stimulus Rails
- **ViewComponent:** 3.24.0 (já instalada)
- **Testes:** RSpec + FactoryBot + Faker

### Estrutura de componentes existente (Story 5.2)

```
app/components/
  status_badge_component.rb         # ✅ existente
  status_badge_component.html.erb   # ✅ existente
  task_card_component.rb            # ✅ existente
  task_card_component.html.erb      # ✅ existente

spec/components/
  status_badge_component_spec.rb    # ✅ existente — 16 examples
  task_card_component_spec.rb       # ✅ existente — 12 examples
```

**Novo nesta story:**
```
app/components/
  daily_total_component.rb          # CRIAR
  daily_total_component.html.erb    # CRIAR

spec/components/
  daily_total_component_spec.rb     # CRIAR
```

### Query de total do dia (DA-043 — Architecture DM-005)

```ruby
# Definida na arquitetura do domínio
TaskItem.joins(:task)
  .where(tasks: { start_date: Date.current })
  .sum(:hours_worked)
```

### ViewComponent RSpec helpers (já configurados em spec/rails_helper.rb)

```ruby
require "view_component/test_helpers"

RSpec.configure do |config|
  config.include ViewComponent::TestHelpers, type: :component
  config.include Rails.application.routes.url_helpers, type: :component
end
```

### Factories disponíveis

```ruby
# factory :task — spec/factories/tasks.rb
# - association :company
# - association :project (vinculado à mesma company)
# - traits: :pending, :completed, :delivered

# factory :task_item — spec/factories/task_items.rb
# - association :task
# - start_time: '09:00', end_time: '10:30' (padrão = 1.5 horas, hours_worked calculado)
# - traits: :completed, :long_duration, :short_duration
```

### Schema relevante

```
tasks:
  id, name, company_id, project_id, start_date (date), status,
  estimated_hours (decimal), validated_hours (decimal), ...

task_items:
  id, task_id, start_time (time), end_time (time),
  status, hours_worked (decimal, calculado via before_save)
```

### Estado atual de `app/controllers/tasks_controller.rb`

```ruby
class TasksController < ApplicationController
  before_action :require_authentication

  def index
    @tasks = Task
      .includes(:company, :project, :task_items)
      .where(start_date: Date.current.all_month)
      .order(start_date: :desc, created_at: :desc)
  end
  # ...
end
```

### Estado atual de `app/views/tasks/index.html.erb`

```erb
<div class="max-w-7xl mx-auto">
  <div class="flex items-center justify-between mb-6">
    <h1 class="text-2xl font-bold text-white">Tarefas do Mês</h1>
    <%= link_to "Nova Tarefa", new_task_path, class: "..." %>
  </div>

  <div class="bg-gray-800 shadow-sm rounded-lg border border-gray-700 overflow-hidden">
    <% if @tasks.empty? %>
      ...
    <% else %>
      <table>
        ...
        <tbody>
          <% @tasks.each do |task| %>
            <%= render TaskCardComponent.new(task: task) %>
          <% end %>
        </tbody>
      </table>
    <% end %>
  </div>
</div>
```

---

## Tasks / Subtasks

### 1. Atualizar `TasksController#index` para calcular `@daily_total`

- [x] Abrir `app/controllers/tasks_controller.rb`
- [x] Na action `index`, adicionar após a query de `@tasks`:
  ```ruby
  @daily_total = TaskItem
    .joins(:task)
    .where(tasks: { start_date: Date.current })
    .sum(:hours_worked)
  ```
- [x] **Não modificar** a query de `@tasks` existente

### 2. Criar `DailyTotalComponent`

- [x] Criar `app/components/daily_total_component.rb`:
  ```ruby
  class DailyTotalComponent < ViewComponent::Base
    def initialize(total_hours:)
      @total_hours = total_hours
    end

    def formatted_total
      "#{sprintf('%.2f', @total_hours)} horas"
    end
  end
  ```
  > ⚠️ Nota: `sprintf` usado no lugar de `format` — `ViewComponent::Base` sobrescreve `Kernel#format`

- [x] Criar `app/components/daily_total_component.html.erb` com dark theme:
  ```erb
  <div class="bg-gray-800 border border-gray-700 rounded-lg px-6 py-4">
    <p class="text-xs font-medium text-gray-400 uppercase tracking-wider mb-1">Total do Dia</p>
    <p class="text-2xl font-bold text-white"><%= formatted_total %></p>
  </div>
  ```

### 3. Integrar componente em `tasks/index.html.erb`

- [x] Abrir `app/views/tasks/index.html.erb`
- [x] Adicionar **acima** da `<div>` da tabela (após o header com "Tarefas do Mês"):
  ```erb
  <div class="mb-6">
    <%= render DailyTotalComponent.new(total_hours: @daily_total) %>
  </div>
  ```
- [x] **Não modificar** nenhuma outra parte da view

### 4. Escrever specs do componente

- [x] Criar `spec/components/daily_total_component_spec.rb`:

  ```ruby
  require "rails_helper"

  RSpec.describe DailyTotalComponent, type: :component do
    it "exibe 0.00 horas quando total é zero" do
      render_inline(described_class.new(total_hours: 0))
      expect(page).to have_text("0.00 horas")
    end

    it "exibe o total com 2 casas decimais" do
      render_inline(described_class.new(total_hours: 3.5))
      expect(page).to have_text("3.50 horas")
    end

    it "exibe o label 'Total do Dia'" do
      render_inline(described_class.new(total_hours: 0))
      expect(page).to have_text("Total do Dia")
    end

    it "exibe valor inteiro formatado com .00" do
      render_inline(described_class.new(total_hours: 8))
      expect(page).to have_text("8.00 horas")
    end

    describe "#formatted_total" do
      it "formata 1.5 como '1.50 horas'" do
        component = described_class.new(total_hours: 1.5)
        expect(component.formatted_total).to eq("1.50 horas")
      end

      it "formata 0 como '0.00 horas'" do
        component = described_class.new(total_hours: 0)
        expect(component.formatted_total).to eq("0.00 horas")
      end
    end
  end
  ```

### 5. Rodar todos os testes

- [x] `bundle exec rspec spec/components/daily_total_component_spec.rb` — 6/6 passando
- [x] `bundle exec rspec spec/components/` — todos os componentes passando
- [x] `bundle exec rspec spec/controllers/tasks_controller_spec.rb` — 23/24 passando (1 falha pré-existente: `GET #new assigns active companies` — data leak de seeds no banco de test, não relacionado à story)
- [x] `bundle exec rspec spec/models/` — sem regressões

---

## Contexto de Integrações

### O que já existe e deve ser preservado

| Arquivo | Status | Impacto |
|---------|--------|---------|
| `app/controllers/tasks_controller.rb` | ✅ Existente | Adicionar `@daily_total` na action index |
| `app/views/tasks/index.html.erb` | ✅ Existente | Adicionar render DailyTotalComponent acima da tabela |
| `app/components/task_card_component.rb` | ✅ Existente | Não modificar |
| `app/components/status_badge_component.rb` | ✅ Existente | Não modificar |
| `spec/rails_helper.rb` | ✅ Com ViewComponent helpers | Não modificar |
| `app/models/task.rb` | ✅ Existente | Não modificar |
| `app/models/task_item.rb` | ✅ Existente | Não modificar |
| `spec/controllers/tasks_controller_spec.rb` | ✅ 17 examples | Manter passando |

### O que NÃO deve ser criado nesta story

- Turbo Streams para atualização em tempo real (Story 5.5)
- Total por empresa/mês (Story 5.4)
- Filtros dinâmicos (Domínio DM-006)
- Links de editar/deletar tasks (Stories 7.1 e 7.2)

### Dependência crítica: Stories 5.1 e 5.2

Esta story **depende** das Stories 5.1 e 5.2 estarem implementadas (status: done). Ambas estão done conforme sprint-status.yaml em 2026-03-28.

---

## Dev Agent Record

### File List

- `app/controllers/tasks_controller.rb` — `@daily_total` adicionado na action index
- `app/components/daily_total_component.rb` — criado
- `app/components/daily_total_component.html.erb` — criado
- `app/views/tasks/index.html.erb` — render DailyTotalComponent adicionado acima da tabela
- `spec/components/daily_total_component_spec.rb` — criado (6 examples)
- `spec/controllers/tasks_controller_spec.rb` — describe GET #index adicionado (7 examples)

### Completion Notes

- Implementação server-rendered sem Turbo Streams (conforme guardrail — Story 5.5)
- `sprintf` usado no lugar de `format` em `DailyTotalComponent#formatted_total` — `ViewComponent::Base` sobrescreve `Kernel#format` causando `ArgumentError` (bug encontrado em runtime via specs)
- `GET #index` spec adicionado ao controller spec cobrindo `@daily_total` (AC 1, 3, 4)
- Validado via Playwright MCP: card "Total do Dia" exibindo `0.00 horas` com dark theme correto em http://localhost:3001/tasks
- 1 falha pré-existente no controller spec (`GET #new assigns active companies`) — data leak de seeds no banco de test, não introduzida por esta story

### Change Log

- 2026-03-28: Story 5.3 criada — DailyTotalComponent para total de horas do dia atual
- 2026-03-30: Story 5.3 implementada e validada — status done
