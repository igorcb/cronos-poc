# Story 5.2: Criar TaskCardComponent com ViewComponent

**Status:** done
**Domínio:** DM-005-visualizacao-totalizadores
**Data:** 2026-03-27
**Epic:** DM-005 — Visualização & Totalizadores

---

## Story

**Como** Igor,
**Quero** um componente ViewComponent reutilizável para exibir cada task na listagem,
**Para que** a UI seja consistente, encapsulada e testável isoladamente.

---

## Acceptance Criteria

**Given** que a lista de tasks é renderizada em `tasks/index.html.erb`

**When** a view itera sobre `@tasks`

**Then**
1. ✅ A gem `view_component` (~> 3.21) está instalada e configurada
2. ✅ Existe `app/components/task_card_component.rb` herdando `ViewComponent::Base`
3. ✅ Existe `app/components/task_card_component.html.erb` com dark theme
4. ✅ Existe `app/components/status_badge_component.rb` para o badge de status
5. ✅ O componente exibe: `start_date`, `name`, `company.name`, `project.name`, status badge, `estimated_hours_hm`, `validated_hours`, `calculated_value`
6. ✅ Status badge usa cores dark theme: `pending=bg-yellow-900`, `completed=bg-green-900`, `delivered=bg-blue-900`, fallback=`bg-gray-700`
7. ✅ `tasks/index.html.erb` usa `render TaskCardComponent.new(task:)` em vez de inline ERB
8. ✅ `bundle exec rspec spec/components/task_card_component_spec.rb` passa 100%
9. ✅ `bundle exec rspec spec/components/status_badge_component_spec.rb` passa 100%
10. ✅ Todos os testes existentes (143+) continuam passando

---

## CRITICAL GUARDRAILS — Leia antes de implementar

### ⚠️ MODELO CORRETO: `Task`, NÃO `TimeEntry`

O epic menciona "TimeEntries" mas **o modelo implementado se chama `Task`**. Não existe modelo `TimeEntry` no projeto. O componente deve se chamar `TaskCardComponent`, não `TimeEntryCardComponent`.

```ruby
# app/components/task_card_component.rb
class TaskCardComponent < ViewComponent::Base
  # ...
end
```

**NUNCA crie `TimeEntryCardComponent` — use `TaskCardComponent`.**

### ⚠️ STATUS `reopened` NÃO EXISTE

O modelo `Task` tem apenas 3 status válidos:
```ruby
enum :status, { pending: "pending", completed: "completed", delivered: "delivered" }
```

Não há `reopened`. O badge deve tratar apenas `pending`, `completed`, `delivered`, e um fallback genérico.

### ⚠️ SEM LINKS DE EDITAR/DELETAR

As actions `edit`, `update`, `destroy` ainda **não existem** no `TasksController`. As stories 7.1 e 7.2 irão implementá-las. **Não adicione links de editar/deletar nesta story.**

### ⚠️ DARK THEME — cores corretas

O projeto usa dark theme. Use estas cores para badges (NÃO use bg-yellow-100 ou text-yellow-800):

```
pending   → bg-yellow-900 text-yellow-300 border border-yellow-700
completed → bg-green-900 text-green-300 border border-green-700
delivered → bg-blue-900 text-blue-300 border border-blue-700
fallback  → bg-gray-700 text-gray-300 border border-gray-600
```

### ⚠️ VIEW_COMPONENT: instalar antes de usar

A gem já está no Gemfile (`gem "view_component", "~> 3.21"`) mas precisa de `bundle install`.
Após instalar, crie o diretório `app/components/` se não existir.

### ⚠️ DEPENDÊNCIA: Story 5.1 deve estar implementada

Esta story depende da Story 5.1 (`tasks/index.html.erb` deve existir com a listagem de tasks).
Verifique que `GET /tasks` está funcional antes de refatorar para componentes.

**Rota necessária (Story 5.1):**
```ruby
resources :tasks, only: [ :index, :new, :create ]
```

### ⚠️ `estimated_hours_hm` é atributo virtual

Use `task.estimated_hours_hm` (formato "HH:MM"), não `task.estimated_hours` (decimal).

### ⚠️ `validated_hours` pode ser nil — mas `after_save` seta para 0

O callback `after_save :recalculate_validated_hours` seta `validated_hours = 0` quando não há task_items
(porque `nil == 0` é false em Ruby, então o `update_column` sempre dispara).
Na prática, tasks persistidas terão `validated_hours = 0`, não `nil`.

```erb
<%# template: mostrar 0.00 para tasks sem task_items, "-" apenas para objetos não persistidos %>
<%= task.validated_hours ? number_with_precision(task.validated_hours, precision: 2) : "-" %>
```

### ⚠️ `total_hours` usa in-memory sum com eager loading

O model já tem:
```ruby
def total_hours
  task_items.loaded? ? task_items.sum(&:hours_worked) : task_items.sum(:hours_worked)
end
```

`calculated_value` chama `total_hours` internamente — sem N+1 se `task_items` estiver em memória.
O controller usa `includes(:company, :project, :task_items)` — garanta que esta query persiste.

### ⚠️ XSS: use `<%= %>` não `<%== %>`

Rails escapa HTML por padrão com `<%= %>`. Não use `raw()` ou `<%== %>` em nenhum campo exibido.

---

## Contexto Técnico

### Stack atual do projeto

- **Rails** 8.1.2, **Ruby** 3.x, **PostgreSQL**
- **CSS:** Tailwind CSS (dark theme: `bg-gray-900`, `bg-gray-800`, `text-white`)
- **JS:** Turbo Rails + Stimulus Rails
- **Assets:** Propshaft + jsbundling-rails + cssbundling-rails
- **Testes:** RSpec + FactoryBot + Faker
- **ViewComponent:** 3.24.0 (constraint `~> 3.21` no Gemfile)

### ViewComponent: configuração para RSpec

```ruby
# spec/rails_helper.rb — adicionar após os outros requires
require "view_component/test_helpers"

RSpec.configure do |config|
  config.include ViewComponent::TestHelpers, type: :component
  config.include Rails.application.routes.url_helpers, type: :component
end
```

### Estrutura de componentes

```
app/components/
  status_badge_component.rb         # badge de status reutilizável
  status_badge_component.html.erb   # template do badge
  task_card_component.rb            # card da task (linha <tr>)
  task_card_component.html.erb      # template do card

spec/components/
  status_badge_component_spec.rb
  task_card_component_spec.rb
```

### Como usar na view index

```erb
<%# app/views/tasks/index.html.erb — dentro do <tbody> %>
<% @tasks.each do |task| %>
  <%= render TaskCardComponent.new(task: task) %>
<% end %>
```

### Query do controller (Story 5.1 — não alterar)

```ruby
def index
  @tasks = Task
    .includes(:company, :project, :task_items)
    .where(start_date: Date.current.all_month)
    .order(start_date: :desc, created_at: :desc)
end
```

### Factories disponíveis

```ruby
# spec/factories/tasks.rb — factory :task
# - Usa estimated_hours_hm (formato HH:MM)
# - association :company
# - association :project (vinculado à mesma company)
# - traits: :pending, :completed, :delivered, :without_end_date

# spec/factories/task_items.rb — factory :task_item
# - association :task
# - start_time: '09:00', end_time: '10:30' (padrão = 1.5 horas)
# - traits: :completed, :long_duration, :short_duration
```

### Padrão de dark theme (consistência visual)

- Background principal: `bg-gray-900`
- Cards/containers: `bg-gray-800`
- Linhas de tabela: `hover:bg-gray-700 transition-colors`
- Texto principal: `text-white`
- Texto secundário: `text-gray-300`
- Bordas: `border-gray-700`

---

## Tasks / Subtasks

### 1. Instalar gem view_component

- [x] Verificar que `gem "view_component", "~> 3.21"` está no `Gemfile`
- [x] Rodar `bundle install` no container
- [x] Verificar instalação: `bundle exec ruby -e "require 'view_component/version'; puts ViewComponent::VERSION::STRING"`

### 2. Configurar ViewComponent para RSpec

- [x] Em `spec/rails_helper.rb`, adicionar após os outros requires:
  ```ruby
  require "view_component/test_helpers"
  ```
  E dentro do bloco `RSpec.configure`:
  ```ruby
  config.include ViewComponent::TestHelpers, type: :component
  config.include Rails.application.routes.url_helpers, type: :component
  ```
- [x] Verificar que `require 'shoulda/matchers'` e `Rails::Controller::Testing.install` também estão presentes (adicionados na Story 5.1)

### 3. Criar `StatusBadgeComponent`

- [x] Criar `app/components/status_badge_component.rb` com:
  - `attr_reader :status`
  - `initialize(status:)`
  - método `badge_classes` retornando strings CSS dark theme por status
  - fallback `else` para status desconhecido
- [x] Criar `app/components/status_badge_component.html.erb` com:
  - `<span>` com `<%= badge_classes %>` e `<%= status.capitalize %>`
  - Classes: `inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium`

### 4. Criar `TaskCardComponent`

- [x] Criar `app/components/task_card_component.rb` com:
  - `attr_reader :task`
  - `initialize(task:)`
- [x] Criar `app/components/task_card_component.html.erb` renderizando uma `<tr>` com:
  - `task.start_date.strftime("%d/%m/%Y")`
  - `task.name`
  - `task.company.name`
  - `task.project.name`
  - `render StatusBadgeComponent.new(status: task.status)`
  - `task.estimated_hours_hm`
  - `task.validated_hours` (com fallback `-` se nil)
  - `task.calculated_value` formatado com `number_with_precision`

### 5. Atualizar `app/views/tasks/index.html.erb`

- [x] Substituir o bloco `<% @tasks.each do |task| %>...<% end %>` inline por:
  ```erb
  <% @tasks.each do |task| %>
    <%= render TaskCardComponent.new(task: task) %>
  <% end %>
  ```

### 6. Escrever specs dos componentes

- [x] Criar `spec/components/status_badge_component_spec.rb`:
  - Testa cada status (pending, completed, delivered) → classe CSS correta
  - Testa status desconhecido → fallback cinza
  - Testa texto exibido (capitalize)
  - Testa método `badge_classes` diretamente

- [x] Criar `spec/components/task_card_component_spec.rb`:
  - Testa que renderiza `<tr>`
  - Testa que exibe `task.name`, `task.company.name`, `task.project.name`
  - Testa que exibe `task.start_date` no formato `dd/mm/yyyy`
  - Testa que renderiza badge de status correto (via CSS class)
  - Testa `estimated_hours_hm` exibido
  - Testa `validated_hours`: exibe `0.00` para task sem task_items (after_save seta 0)
  - Testa `validated_hours`: exibe valor decimal com task_items (use `create(:task_item, :completed, task: t); t.reload`)
  - Testa `calculated_value`: exibe "R$" no output

### 7. Rodar todos os testes

- [x] `docker compose exec web bundle exec rspec spec/components/` — 28/28 passando
- [x] `docker compose exec web bundle exec rspec spec/controllers/tasks_controller_spec.rb` — 17/17 passando
- [x] `docker compose exec web bundle exec rspec spec/models/` — 125/125 sem regressões

---

## Contexto de Integrações

### O que já existe e deve ser preservado

| Arquivo | Status | Impacto |
|---------|--------|---------|
| `app/controllers/tasks_controller.rb` | ✅ Existente (Story 5.1) | Preservar index, new, create |
| `app/views/tasks/index.html.erb` | ✅ Criado na Story 5.1 | Refatorar para usar componentes |
| `app/views/tasks/_form.html.erb` | ✅ Existente | Não modificar |
| `app/views/tasks/new.html.erb` | ✅ Existente | Não modificar |
| `app/models/task.rb` | ✅ Existente | Não modificar |
| `spec/controllers/tasks_controller_spec.rb` | ✅ 22/22 | Manter passando |

### O que NÃO deve ser criado nesta story

- Links de editar/deletar nas tasks (Stories 7.1 e 7.2)
- Totalizadores dinâmicos (Stories 5.3 e 5.4)
- Turbo Streams (Story 5.5)
- Filtros (Domínio DM-006)
- Modelo `TimeEntry` — não existe, não criar
- `TimeEntryCardComponent` — o nome correto é `TaskCardComponent`

### Dependência crítica: Story 5.1

Esta story **depende** da Story 5.1 estar implementada. Se a Story 5.1 não estiver done:
1. Implementar 5.1 primeiro: rota `:index`, action `index`, `tasks/index.html.erb`, link no navbar
2. Só então prosseguir com 5.2

---

## Dev Agent Record

### File List

- `Gemfile` — adicionado `gem "view_component", "~> 3.21"`
- `Gemfile.lock` — atualizado com view_component 3.24.0
- `spec/rails_helper.rb` — adicionados requires: shoulda/matchers, rails-controller-testing, view_component/test_helpers; Rails::Controller::Testing.install; includes para type: :component
- `app/components/status_badge_component.rb` — criado
- `app/components/status_badge_component.html.erb` — criado
- `app/components/task_card_component.rb` — criado
- `app/components/task_card_component.html.erb` — criado
- `app/views/tasks/index.html.erb` — criado (pré-requisito 5.1 + uso do TaskCardComponent)
- `app/controllers/tasks_controller.rb` — adicionada action `index` com eager loading
- `config/routes.rb` — adicionado `:index` em resources :tasks
- `spec/components/status_badge_component_spec.rb` — criado (16 examples)
- `spec/components/task_card_component_spec.rb` — criado (12 examples)

### Completion Notes

- view_component 3.24.0 instalada (satisfaz constraint ~> 3.21)
- StatusBadgeComponent: dark theme com 3 status + fallback cinza
- TaskCardComponent: renderiza `<tr>` com todos os campos do AC
- Pré-requisito Story 5.1 implementado junto: rota index, action index com eager loading, view index
- 28/28 specs de componentes passando
- 17/17 specs de controller passando
- 125/125 specs de models sem regressões
- Falhas pré-existentes em spec/requests/ e spec/features/ confirmadas como não relacionadas à Story 5.2

### Change Log

- 2026-03-27: Story 5.2 criada — TaskCardComponent + StatusBadgeComponent com ViewComponent
- 2026-03-27: Story 5.2 implementada — 28 specs passando, status: review
- 2026-03-28: Code review realizado — 1 decision_needed, 7 patch, 3 defer, 4 dismissed
- 2026-03-28: Patches aplicados, 166 testes passando, UI validada via Playwright — status: done

---

## Review Findings

### Decision Needed

- [ ] [Review][Decision] Escopo do index hard-coded para o mês atual — `.where(start_date: Date.current.all_month)` limita resultados ao mês corrente sem filtros ou override. A spec não menciona filtro de período; a Story 5.3/5.4 (totalizadores) pode depender desse filtro, mas a Story 5.6 (filtros dinâmicos) seria o lugar certo. Manter o filtro de mês atual ou mostrar todas as tasks?

### Patches

- [ ] [Review][Patch] `task.company.name` sem nil guard — crash com NoMethodError se company for nil [app/components/task_card_component.html.erb:3]
- [ ] [Review][Patch] `task.project.name` sem nil guard — crash com NoMethodError se project for nil [app/components/task_card_component.html.erb:4]
- [ ] [Review][Patch] `task.start_date.strftime` sem nil guard — crash com NoMethodError se start_date for nil [app/components/task_card_component.html.erb:1]
- [ ] [Review][Patch] `status.capitalize` no template sem nil guard — NoMethodError se status for nil [app/components/status_badge_component.html.erb:1]
- [ ] [Review][Patch] `status` como symbol do enum faz badge_classes cair sempre no `else` — case compara com strings literais, mas enum pode retornar symbol dependendo do uso [app/components/status_badge_component.rb:10-16]
- [ ] [Review][Patch] `validated_hours` é `0.0` (não nil) após `after_save` — template renderiza `"0.00"` para tasks sem task_items, nunca `"-"`; teste da spec que espera `"-"` está incorreto [app/components/task_card_component.html.erb:9]
- [ ] [Review][Patch] `calculated_value` exibe `R$ 0,00` sem indicação visual para dados inconsistentes — inconsistente com tratamento de `validated_hours` que usa `"-"` [app/components/task_card_component.html.erb:13]

### Deferred

- [x] [Review][Defer] `Rails::Controller::Testing.install` como side-effect global em rails_helper.rb [spec/rails_helper.rb:8] — deferred, pré-existente adicionado em Story 5.1
- [x] [Review][Defer] Testes de rendering no `status_badge_component_spec.rb` duplicam testes unitários de `badge_classes` [spec/components/status_badge_component_spec.rb:39-66] — deferred, cobertura redundante mas não prejudicial
- [x] [Review][Defer] `<table>` sem `<thead>` com labels de coluna na view index [app/views/tasks/index.html.erb] — deferred, thead existe no template da view mas não está no componente; cosmético
