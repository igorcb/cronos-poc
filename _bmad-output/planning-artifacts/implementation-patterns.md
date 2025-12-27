# Padrões de Implementação e Regras de Consistência - Cronos POC

**Autor:** Igor
**Data:** 2025-12-27
**Projeto:** cronos-poc

Este documento define os padrões obrigatórios que todos os agentes AI devem seguir ao implementar código para o projeto Cronos POC.

---

## Pontos Críticos de Conflito Identificados

**15 áreas** onde agentes AI poderiam fazer escolhas diferentes, causando incompatibilidades no código Rails + Hotwire + Tailwind.

---

## Categoria 1: Naming Patterns (Rails Conventions)

### Database Naming (PostgreSQL)

```ruby
# ✅ CORRETO - Rails conventions
- Tabelas: plural snake_case (users, time_entries, companies)
- Colunas: singular snake_case (email, created_at, hourly_rate)
- Foreign Keys: singular_table_id (user_id, company_id, project_id)
- Índices: index_table_on_column (index_time_entries_on_company_id)
- Constraints: check_table_condition (check_end_after_start)
- Timestamps: SEMPRE created_at, updated_at (não createdAt ou timestamp)

# ❌ INCORRETO
- Tabelas em CamelCase ou singular
- Colunas em camelCase
- FKs com prefixo "fk_" ou sufixo "_ref"
```

### Model Naming

```ruby
# ✅ CORRETO
class TimeEntry < ApplicationRecord  # Singular, CamelCase
end

class Company < ApplicationRecord
end

# ❌ INCORRETO
class TimeEntries  # Plural
class time_entry   # snake_case
```

### Controller Naming

```ruby
# ✅ CORRETO
class TimeEntriesController < ApplicationController  # Plural + Controller
  def index; end
  def show; end
  def create; end
end

# ❌ INCORRETO
class TimeEntryController  # Singular
class TimeEntriesCtrl      # Abreviação
```

### Route Naming

```ruby
# ✅ CORRETO
resources :time_entries  # Plural snake_case
resources :companies
get 'dashboard', to: 'dashboard#index'  # Ações como snake_case

# ❌ INCORRETO
resources :timeEntries   # camelCase
resources :time_entry    # Singular
```

### ViewComponent Naming

```ruby
# ✅ CORRETO
class TimeEntryCardComponent < ViewComponent::Base  # Sufixo Component
end

# Arquivo: app/components/time_entry_card_component.rb
# Template: app/components/time_entry_card_component.html.erb

# ❌ INCORRETO
class TimeEntryCard  # Sem sufixo Component
class TimeEntryCardView
```

### Stimulus Controller Naming

```javascript
// ✅ CORRETO
// Arquivo: app/javascript/controllers/form_validation_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["startTime", "endTime"]
}

// Uso em HTML:
// data-controller="form-validation"  // kebab-case
// data-form-validation-target="startTime"  // camelCase para targets

// ❌ INCORRETO
// Arquivo: form_validationController.js
// data-controller="formValidation"  // camelCase no HTML
```

---

## Categoria 2: Structure Patterns

### Project Organization (Obrigatória)

```
app/
├── controllers/
│   ├── application_controller.rb
│   ├── time_entries_controller.rb
│   ├── companies_controller.rb
│   └── concerns/
│       └── authentication.rb
├── models/
│   ├── application_record.rb
│   ├── user.rb
│   ├── time_entry.rb
│   ├── company.rb
│   ├── project.rb
│   └── concerns/
│       ├── calculable.rb
│       └── filterable.rb
├── views/
│   ├── layouts/
│   │   └── application.html.erb
│   ├── time_entries/
│   │   ├── index.html.erb
│   │   ├── _form.html.erb
│   │   └── _time_entry.html.erb
│   └── shared/
│       ├── _flash.html.erb
│       └── _navbar.html.erb
├── components/
│   ├── time_entry_card_component.rb
│   ├── time_entry_card_component.html.erb
│   ├── status_badge_component.rb
│   └── totalizer_component.rb
├── services/
│   └── monthly_report_generator.rb
├── javascript/
│   └── controllers/
│       ├── form_validation_controller.js
│       ├── project_selector_controller.js
│       └── filter_controller.js
└── assets/
    └── stylesheets/
        └── application.tailwind.css
```

### Test Organization (RSpec)

```
spec/
├── models/
│   ├── user_spec.rb
│   ├── time_entry_spec.rb
│   └── company_spec.rb
├── requests/
│   ├── time_entries_spec.rb
│   └── companies_spec.rb
├── system/
│   ├── time_tracking_spec.rb
│   └── authentication_spec.rb
├── components/
│   └── time_entry_card_component_spec.rb
├── services/
│   └── monthly_report_generator_spec.rb
├── factories/
│   ├── users.rb
│   ├── time_entries.rb
│   ├── companies.rb
│   └── projects.rb
└── support/
    ├── factory_bot.rb
    └── database_cleaner.rb
```

### Regras de Localização

```ruby
# ✅ CORRETO
# Concerns de Model: app/models/concerns/
# Concerns de Controller: app/controllers/concerns/
# Service Objects: app/services/
# ViewComponents: app/components/
# Stimulus Controllers: app/javascript/controllers/

# ❌ INCORRETO
# Concerns em /lib
# Services em /app/lib
# Components misturados com views
```

---

## Categoria 3: Format Patterns

### JSON API Responses (se necessário no futuro)

```ruby
# ✅ CORRETO - Formato consistente
{
  "data": {
    "id": 1,
    "type": "time_entry",
    "attributes": {
      "date": "2025-12-27",
      "start_time": "08:30:00",
      "end_time": "12:00:00",
      "duration_minutes": 210,
      "calculated_value": "157.50",
      "status": "pending"
    },
    "relationships": {
      "company": {
        "data": { "id": 1, "type": "company" }
      }
    }
  }
}

# Error response
{
  "error": {
    "type": "validation_error",
    "message": "End time must be after start time",
    "details": {
      "field": "end_time",
      "code": "invalid_range"
    }
  }
}

# ❌ INCORRETO
# Respostas sem wrapper
# Campos em camelCase no JSON
# Erros sem estrutura consistente
```

### Date/Time Formats

```ruby
# ✅ CORRETO
# Database: PostgreSQL date, time, datetime types nativos
# JSON API: ISO 8601 strings
"date": "2025-12-27"
"start_time": "08:30:00"
"created_at": "2025-12-27T08:30:00Z"

# Views (ERB): strftime com I18n
<%= entry.date.strftime('%d/%m/%Y') %>
<%= entry.start_time.strftime('%H:%M') %>

# ❌ INCORRETO
# Timestamps Unix em APIs
# Formatos MM/DD/YYYY no banco
# Strings de data sem timezone
```

### Status Enums

```ruby
# ✅ CORRETO - String enums no banco
# app/models/time_entry.rb
STATUSES = %w[pending completed reopened delivered].freeze

validates :status, inclusion: { in: STATUSES }

# Migration
t.string :status, null: false, default: 'pending'

# ❌ INCORRETO
# Integers para status (dificulta debug)
# Enums Rails (problemas com migrations)
# Status em camelCase ou PascalCase
```

---

## Categoria 4: Hotwire Patterns

### Turbo Frame IDs

```erb
<!-- ✅ CORRETO - IDs descritivos e únicos -->
<turbo-frame id="time_entry_<%= entry.id %>">
  <%= render TimeEntryCardComponent.new(entry: entry) %>
</turbo-frame>

<turbo-frame id="daily_totals_<%= Date.today.to_s %>">
  <%= render 'dashboard/daily_totals' %>
</turbo-frame>

<!-- Padrão: resource_singular + id ou descrição única -->

<!-- ❌ INCORRETO -->
<turbo-frame id="entry">  <!-- Não único -->
<turbo-frame id="TimeEntry123">  <!-- CamelCase -->
```

### Turbo Stream Broadcast Naming

```ruby
# ✅ CORRETO
# app/models/time_entry.rb
after_commit :broadcast_update

def broadcast_update
  broadcast_replace_to(
    "user_#{user_id}_time_entries",  # Padrão: resource_id_collection
    target: "time_entry_#{id}",
    partial: "time_entries/time_entry",
    locals: { time_entry: self }
  )
end

# ❌ INCORRETO
broadcast_replace_to("timeEntries")  # camelCase
broadcast_replace_to("entries")      # Genérico demais
```

### Stimulus Controller Actions

```javascript
// ✅ CORRETO
export default class extends Controller {
  connect() { }
  disconnect() { }

  validateTimes(event) { }  // camelCase para métodos JS
  updateTotal(event) { }
  resetForm(event) { }
}
```

```erb
<!-- ✅ CORRETO - Uso em HTML -->
<form data-controller="form-validation"
      data-action="change->form-validation#validateTimes">
  <!-- kebab-case no HTML, camelCase no JS -->
</form>

<!-- ❌ INCORRETO -->
<form data-action="change->formValidation#validateTimes">  <!-- camelCase controller -->
```

---

## Categoria 5: Tailwind CSS Patterns

### Utility Classes Order

```erb
<!-- ✅ CORRETO - Ordem consistente: layout → sizing → spacing → colors → effects -->
<div class="flex items-center justify-between w-full p-4 mt-2 bg-white border rounded-lg shadow-sm hover:shadow-md transition">

<!-- Padrão recomendado:
1. Display/Position (flex, grid, block, absolute)
2. Sizing (w-full, h-screen, max-w-lg)
3. Spacing (p-4, m-2, space-x-4)
4. Typography (text-lg, font-bold)
5. Colors (bg-white, text-gray-700)
6. Borders (border, rounded-lg)
7. Effects (shadow-sm, opacity-50)
8. Transitions/Animations (transition, duration-300)
9. Responsive (sm:flex, md:w-1/2)
-->

<!-- ❌ INCORRETO - Ordem aleatória -->
<div class="shadow-sm bg-white transition rounded-lg p-4 flex w-full">
```

### Breakpoint Usage

```erb
<!-- ✅ CORRETO - Mobile-first (sem prefixo = mobile) -->
<div class="w-full md:w-1/2 lg:w-1/3">
  <!-- Mobile: full width, Tablet: 50%, Desktop: 33% -->
</div>

<!-- Breakpoints:
- (nenhum): < 768px (mobile)
- md: 768px - 1023px (tablet)
- lg: ≥ 1024px (desktop)
-->

<!-- ❌ INCORRETO -->
<div class="sm:w-full md:w-1/2">  <!-- Não usar sm para mobile base -->
```

---

## Categoria 6: Database & Migration Patterns

### Migration Structure

```ruby
# ✅ CORRETO
class CreateTimeEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :time_entries, if_not_exists: true do |t|
      t.references :user, null: false, foreign_key: true, if_not_exists: true
      t.references :company, null: false, foreign_key: true, if_not_exists: true
      t.date :date, null: false
      t.string :status, null: false, default: 'pending'
      t.decimal :calculated_value, precision: 10, scale: 2

      t.timestamps
    end

    # Índices SEMPRE após create_table
    add_index :time_entries, [:user_id, :date], if_not_exists: true
    add_index :time_entries, :company_id, if_not_exists: true
  end
end

# SEMPRE usar if_not_exists: true (conforme CLAUDE.md)
# SEMPRE null: false para campos obrigatórios
# SEMPRE precision/scale para decimals monetários
# SEMPRE timestamps (created_at, updated_at)

# ❌ INCORRETO
create_table :TimeEntries  # CamelCase
t.integer :user_id  # Usar t.references ao invés
t.float :value  # NUNCA Float para dinheiro, usar decimal
```

### Index Naming

```ruby
# ✅ CORRETO
add_index :time_entries, :status, if_not_exists: true
add_index :time_entries, [:user_id, :date], if_not_exists: true, name: 'index_entries_on_user_and_date'

# Índices compostos: nomes explícitos quando > 2 colunas

# ❌ INCORRETO
add_index :time_entries, :status, name: 'idx_status'  # Muito curto
```

### Foreign Key Constraints

```ruby
# ✅ CORRETO
t.references :company, null: false, foreign_key: true, if_not_exists: true

# Ou explícito:
add_foreign_key :time_entries, :companies, if_not_exists: true

# ❌ INCORRETO
t.integer :company_id  # Sem FK constraint
add_foreign_key sem if_not_exists
```

---

## Categoria 7: Testing Patterns (RSpec)

### Describe/Context/It Structure

```ruby
# ✅ CORRETO
RSpec.describe TimeEntry, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:date) }
    it { should validate_presence_of(:start_time) }

    context 'when end_time is before start_time' do
      let(:entry) { build(:time_entry, start_time: '10:00', end_time: '09:00') }

      it 'is invalid' do
        expect(entry).not_to be_valid
        expect(entry.errors[:end_time]).to include('deve ser posterior ao horário de início')
      end
    end
  end

  describe '#calculate_duration' do
    let(:entry) { create(:time_entry, start_time: '08:00', end_time: '12:00') }

    it 'calculates duration in minutes' do
      entry.calculate_duration
      expect(entry.duration_minutes).to eq(240)
    end
  end
end

# Padrão:
# - describe para métodos/grupos lógicos
# - context para cenários específicos ("when", "with", "without")
# - it para assertions individuais
# - let para setup de dados
# - create para persistir, build para não persistir

# ❌ INCORRETO
describe 'testa validações'  # Português + vago
it 'deve funcionar'  # Não descreve o que testa
expect(entry.valid?).to eq(false)  # Use be_valid
```

### Factory Naming

```ruby
# ✅ CORRETO
# spec/factories/time_entries.rb
FactoryBot.define do
  factory :time_entry do
    association :user
    association :company
    association :project
    date { Date.today }
    start_time { '08:00' }
    end_time { '12:00' }
    activity { Faker::Lorem.sentence }
    status { 'pending' }

    trait :completed do
      status { 'completed' }
    end

    trait :with_custom_hours do
      start_time { '14:00' }
      end_time { '18:00' }
    end
  end
end

# Uso:
create(:time_entry)
create(:time_entry, :completed)
create(:time_entry, :with_custom_hours, company: specific_company)

# ❌ INCORRETO
factory :TimeEntry  # CamelCase
factory :entry  # Nome genérico demais
```

---

## Enforcement Guidelines

### Todos os Agentes AI DEVEM:

1. **Seguir Rails Conventions rigorosamente:**
   - Tabelas plural, Models singular
   - snake_case para Ruby, kebab-case para HTML/CSS
   - Timestamps obrigatórios em todas as tabelas

2. **Usar `if_not_exists: true` em TODAS as migrations:**
   - create_table, add_column, add_index, add_foreign_key
   - Conforme documentado em CLAUDE.md do projeto

3. **Validar em tripla camada:**
   - Database constraints (NOT NULL, CHECK)
   - Model validations (ActiveRecord)
   - Client-side (Stimulus)

4. **Nomear Turbo Frames/Streams consistentemente:**
   - Padrão: `resource_id_description`
   - Exemplo: `time_entry_123`, `user_1_totals`

5. **Organizar código por convenção Rails:**
   - Concerns em /concerns
   - Services em /services
   - Components em /components
   - Specs espelhando estrutura de /app

6. **Usar decimal para valores monetários:**
   - NUNCA Float ou Integer
   - Precision 10, scale 2
   - Cálculos em BigDecimal

7. **Seguir ordem de utility classes Tailwind:**
   - Layout → Sizing → Spacing → Colors → Effects
   - Mobile-first (sem prefixo = mobile)

### Pattern Enforcement

- **Linting:** Rubocop irá validar Ruby style
- **Tests:** RSpec deve seguir estrutura describe/context/it
- **Code Review:** Validar padrões Hotwire/Tailwind manualmente
- **Migration Review:** SEMPRE verificar if_not_exists antes de merge

### Atualização de Padrões

- Padrões devem ser documentados neste arquivo
- Mudanças requerem atualização deste documento
- Novos padrões devem ser comunicados a todos os agentes

---

## Pattern Examples

### ✅ Exemplo Completo CORRETO

```ruby
# Migration
class CreateCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :companies, if_not_exists: true do |t|
      t.string :name, null: false
      t.decimal :hourly_rate, precision: 10, scale: 2, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :companies, :name, if_not_exists: true
    add_index :companies, :active, if_not_exists: true
  end
end

# Model
class Company < ApplicationRecord
  has_many :projects
  has_many :time_entries

  validates :name, presence: true, uniqueness: true
  validates :hourly_rate, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where(active: true) }
end

# Controller
class CompaniesController < ApplicationController
  def index
    @companies = Company.active.order(:name)
  end

  def create
    @company = Company.new(company_params)

    if @company.save
      redirect_to companies_path, notice: 'Empresa criada com sucesso'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def company_params
    params.require(:company).permit(:name, :hourly_rate)
  end
end

# ViewComponent
class CompanyCardComponent < ViewComponent::Base
  def initialize(company:)
    @company = company
  end

  private

  attr_reader :company
end

# ViewComponent Template
<div class="flex items-center justify-between p-4 bg-white border rounded-lg shadow-sm">
  <div>
    <h3 class="text-lg font-semibold"><%= company.name %></h3>
    <p class="text-sm text-gray-600">R$ <%= number_to_currency(company.hourly_rate, unit: '') %>/hora</p>
  </div>
  <%= link_to "Editar", edit_company_path(company), class: "text-blue-600 hover:underline" %>
</div>

# RSpec
RSpec.describe Company, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:hourly_rate) }
    it { should validate_numericality_of(:hourly_rate).is_greater_than(0) }
  end

  describe 'associations' do
    it { should have_many(:projects) }
    it { should have_many(:time_entries) }
  end

  describe '.active' do
    let!(:active_company) { create(:company, active: true) }
    let!(:inactive_company) { create(:company, active: false) }

    it 'returns only active companies' do
      expect(Company.active).to include(active_company)
      expect(Company.active).not_to include(inactive_company)
    end
  end
end
```

### ❌ Anti-Patterns (EVITAR)

```ruby
# ❌ Migration sem if_not_exists
create_table :Companies  # CamelCase
t.float :hourly_rate  # Float para dinheiro
t.integer :status  # Enum como integer

# ❌ Model sem validações
class Company
  # Sem validates
end

# ❌ Controller sem strong parameters
def create
  @company = Company.create(params[:company])  # Mass assignment vulnerability
end

# ❌ ViewComponent sem sufixo Component
class CompanyCard
end

# ❌ RSpec genérico
it 'should work' do
  expect(true).to be_truthy
end

# ❌ Tailwind classes desordenadas
<div class="shadow-sm bg-white p-4 rounded-lg flex">
```

---

**Todos os padrões acima são OBRIGATÓRIOS para garantir consistência entre agentes AI.**
