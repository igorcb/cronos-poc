c# Story 4.2: Criar Model TaskItem com Validações e Cálculos

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->
<!-- Ultimate context engine analysis completed - comprehensive developer guide created -->

## Story

**Como** desenvolvedor,
**Quero** criar tabela task_items para registro granular de horas com cálculos automáticos,
**Para que** cada período de trabalho seja registrado individualmente com precisão.

## Acceptance Criteria

**Given** que tabela tasks existe

**When** crio migration CreateTaskItems

**Then**
1. migration usa `create_table :task_items, if_not_exists: true`
2. possui `t.references :task, null: false, foreign_key: true, if_not_exists: true`
3. possui `t.time :start_time, null: false`
4. possui `t.time :end_time, null: false`
5. possui `t.decimal :hours_worked, precision: 10, scale: 2, null: false`
6. possui `t.string :status, null: false, default: 'pending'`
7. possui timestamps
8. índices criados: `task_id`, `status`, `[task_id, created_at]` com `if_not_exists: true`
9. model TaskItem possui validações: presence de task, start_time, end_time, status
10. model possui enum status: { pending: 'pending', completed: 'completed' }
11. model possui validação customizada: end_time > start_time
12. model possui validação customizada: task não pode ser 'delivered'
13. model possui before_save :calculate_hours_worked
14. model possui after_save :update_task_status
15. model possui after_destroy :update_task_status
16. `rails db:migrate` executa sem erros

## Tasks / Subtasks

- [x] Criar migration CreateTaskItems
  - [x] Usar `create_table :task_items, if_not_exists: true`
  - [x] Adicionar coluna `task_id` (references, null: false, foreign_key: true, if_not_exists: true)
  - [x] Adicionar coluna `start_time` (time, null: false)
  - [x] Adicionar coluna `end_time` (time, null: false)
  - [x] Adicionar coluna `hours_worked` (decimal, precision: 10, scale: 2, null: false)
  - [x] Adicionar coluna `status` (string, null: false, default: 'pending')
  - [x] Adicionar timestamps
  - [x] Criar índice em `task_id` com `if_not_exists: true`
  - [x] Criar índice em `status` com `if_not_exists: true`
  - [x] Criar índice composto `[task_id, created_at]` com `if_not_exists: true`
  - [x] Executar `rails db:migrate`

- [x] Criar model TaskItem
  - [x] Adicionar `belongs_to :task`
  - [x] Adicionar validação `validates :task_id, presence: true`
  - [x] Adicionar validação `validates :start_time, presence: true`
  - [x] Adicionar validação `validates :end_time, presence: true`
  - [x] Adicionar validação `validates :status, presence: true, inclusion: { in: %w[pending completed] }`
  - [x] Adicionar enum status: { pending: 'pending', completed: 'completed' }
    - **NOTA CRÍTICA:** Usar sintaxe Rails 8.1: `enum :status, { pending: 'pending', completed: 'completed' }` (sem `_prefix: true` por conflito)
  - [x] Adicionar validação customizada `end_time_after_start_time`
  - [x] Adicionar validação customizada `task_must_not_be_delivered`
  - [x] Adicionar callback `before_save :calculate_hours_worked`
  - [x] Adicionar callback `after_save :update_task_status`
  - [x] Adicionar callback `after_destroy :update_task_status`
  - [x] Adicionar scopes: `scope :by_task`, `scope :recent_first`

- [x] Testar migrations
  - [x] Executar `rails db:migrate`
  - [x] Verificar se tabela foi criada
  - [x] Verificar se índices foram criados

## Dev Notes

### EPIC CONTEXT: Task Management System
**Epic 4 foi reformulado de TimeEntry para Task + TaskItem architecture**

**Conceito Chave:**
- **Task** = Tarefa gerenciável (status automático, valores calculados)
- **TaskItem** = Registro granular de horas dentro de uma Task
- TaskItems controlam o status da Task pai automaticamente via callbacks

**Regra de Status Automático (CRÍTICA):**
```
Task.status = 'pending'  quando último TaskItem criado está 'pending'
Task.status = 'completed' quando último TaskItem criado está 'completed'
Task.status = 'delivered' é DEFINIDO MANUALMENTE e torna Task READ-ONLY
```

**Algoritmo de Recálculo:**
```ruby
def recalculate_status!
  return if delivered? # Não recalcula se já está delivered

  latest_item = task_items.order(created_at: :desc).first
  return unless latest_item

  new_status = latest_item.completed? ? 'completed' : 'pending'
  update_column(:status, new_status) if status != new_status
end
```

### Architecture Patterns & Constraints

**Padrão de Validação Tripla Camada (ARQ17-ARQ21):**
1. **Migration Level:** `null: false`, check constraints
2. **Model Level:** `validates`, custom validators
3. **Client Level:** Stimulus controllers

**Padrão `if_not_exists: true` (ARQ18 - OBRIGATÓRIO):**
```ruby
create_table :task_items, if_not_exists: true do |t|
  t.references :task, null: false, foreign_key: true, if_not_exists: true
  # ...
end

add_index :task_items, :task_id, if_not_exists: true
```

**Cálculos de Tempo (CRÍTICO - ARQ26):**
- `hours_worked` é calculado automaticamente via `before_save`
- Fórmula: `(end_time - start_time) / 3600.0` (converte segundos para horas)
- Arredondamento: `.round(2)` para 2 casas decimais

**Tipos de Dados (ARQ25):**
- `time` para `start_time` e `end_time` (hora apenas, sem data)
- `decimal precision: 10, scale: 2` para `hours_worked` (NUNCA Float)

**Callbacks ActiveRecord (CRÍTICO):**
```ruby
before_save :calculate_hours_worked        # Calcula duração
after_save :update_task_status             # Recalcula status da Task
after_destroy :update_task_status          # Recalcula ao deletar
```

### Project Structure Notes

**Paths (Rails Conventions):**
- Migration: `db/migrate/YYYYMMDDHHMMSS_create_task_items.rb`
- Model: `app/models/task_item.rb`
- Factory: `spec/factories/task_items.rb`
- Tests: `spec/models/task_item_spec.rb`

**Naming Conventions (ARQ43-ARQ44):**
- Table: `task_items` (snake_case plural)
- Model: `TaskItem` (CamelCase singular)
- Foreign Key: `task_id` (snake_case singular + _id)

**Associações:**
```ruby
# app/models/task_item.rb
class TaskItem < ApplicationRecord
  belongs_to :task
end

# app/models/task.rb
class Task < ApplicationRecord
  has_many :task_items, dependent: :destroy
end
```

### Testing Standards Summary

**RSpec Structure:**
- Model tests: `spec/models/task_item_spec.rb`
- Factory: `spec/factories/task_items.rb`

**FactoryBot Pattern (Baseado em Story 4.1):**
```ruby
# spec/factories/task_items.rb
FactoryBot.define do
  factory :task_item do
    task { association :task }
    start_time { '09:00' }
    end_time { '10:30' }
    status { 'pending' }

    trait :completed do
      status { 'completed' }
    end

    trait :long_duration do
      start_time { '08:00' }
      end_time { '18:30' }
    end
  end
end
```

**Test Coverage Required (Baseado em Task Spec - 34 testes):**
1. Validations de presence (task, start_time, end_time, status)
2. Enum status (pending, completed)
3. Validação customizada: `end_time_after_start_time`
4. Validação customizada: `task_must_not_be_delivered`
5. Callback `calculate_hours_worked`:
   - Calcula corretamente (end_time - start_time) / 3600.0
   - Testar 09:00 as 10:30 => 1.5
   - Testar 08:00 as 12:15 => 4.25
6. Callback `update_task_status`:
   - Chama `task.recalculate_status!`
7. Scopes: `by_task`, `recent_first`
8. Associação `belongs_to :task`

**RSpec Matchers (Shoulda Matchers):**
```ruby
it { should belong_to(:task) }
it { should validate_presence_of(:task) }
it { should validate_presence_of(:start_time) }
it { should validate_presence_of(:end_time) }
it { should define_enum_for(:status).with_values(%w[pending completed]) }
```

### Previous Story Intelligence (Story 4.1)

**Aprendizados Críticos da Implementação de Task:**

1. **Enum sem `_prefix: true` (Rails 8.1):**
   - Usar sintaxe: `enum :status, { pending: 'pending', completed: 'completed', delivered: 'delivered' }`
   - Prefix gera conflito com métodos do Rails 8.1
   - **Aplicar para TaskItem também**

2. **Scopes individuais removidos:**
   - Não criar scopes `:pending`, `:completed` como scopes individuais
   - Eles já são métodos do enum
   - **TaskItem deve seguir o mesmo padrão**

3. **Validação customizada pattern:**
   ```ruby
   validate :custom_validation_name

   private

   def custom_validation_name
     if condition_fails
       errors.add(:field, "mensagem de erro")
     end
   end
   ```

4. **Callbacks usando métodos privados:**
   ```ruby
   before_save :callback_method

   private

   def callback_method
     # lógica aqui
   end
   ```

5. **Testes comprehensivos:**
   - Story 4.1 implementou 34 testes
   - TaskItem deve ter cobertura similar (~25-30 testes)
   - Testar TODOS os callbacks, validações e cálculos

6. **Estrutura de Model (padrão estabelecido):**
   ```ruby
   class TaskItem < ApplicationRecord
     # ASSOCIAÇÕES
     belongs_to :task

     # VALIDAÇÕES
     validates :field, presence: true
     validate :custom_validation

     # ENUMS
     enum :status, { pending: 'pending', completed: 'completed' }

     # CALLBACKS
     before_save :method_name
     after_save :method_name
     after_destroy :method_name

     # SCOPES
     scope :by_task, ->(task_id) { where(task_id: task_id) }
     scope :recent_first, -> { order(created_at: :desc) }

     private

     # métodos privados aqui
   end
   ```

### Git Intelligence

**Commits Recentes (Contexto de Padrões):**
```
b37b2d7 docs: Update story status and documentation after code review
3670602 feat: Implement Task model with validations and tests - Story 4.1
12ee2f3 feat: Refactor Epic 4 from TimeEntry to Task/TaskItem model
```

**Padrão de Commit Mensagem:**
- `feat:` para novas features
- Story number no título
- Descrição concisa do que foi implementado

**Arquivos Modificados em Story 4.1 (Referência):**
- `app/models/task.rb` (novo)
- `app/models/company.rb` (associação adicionada)
- `app/models/project.rb` (associação adicionada)
- `spec/factories/tasks.rb` (novo)
- `spec/models/task_spec.rb` (novo, 34 testes)

**TaskItem deve seguir o mesmo padrão.**

### Critical Implementation Details

**1. Cálculo de Duração (MATÉMATICA CRÍTICA):**
```ruby
def calculate_hours_worked
  return unless start_time.present? && end_time.present?

  duration_in_seconds = (end_time - start_time)
  self.hours_worked = (duration_in_seconds / 3600.0).round(2)
end
```

**Exemplos:**
- 09:00 as 10:30 = (10:30 - 09:00) = 5400 segundos / 3600 = 1.5 horas ✅
- 08:00 as 12:15 = (12:15 - 08:00) = 14700 segundos / 3600 = 4.08333... → 4.08 horas ⚠️

**IMPORTANTE:** Testar arredondamento correto!

**2. Validação de Task Delivered:**
```ruby
def task_must_not_be_delivered
  return unless task.present?

  if task.delivered?
    errors.add(:base, "Não é possível modificar itens de tarefa já entregue")
  end
end
```

**Comportamento Esperado:**
- Bloqueia criação de TaskItem se Task.status == 'delivered'
- Bloqueia edição de TaskItem se Task.status == 'delivered'
- Bloqueia deleção de TaskItem se Task.status == 'delivered'

**3. Callback de Atualização de Status:**
```ruby
def update_task_status
  task.recalculate_status!
end
```

**Fluxo:**
1. TaskItem criado → `after_save` → chama `task.recalculate_status!`
2. TaskItem editado → `after_save` → chama `task.recalculate_status!`
3. TaskItem deletado → `after_destroy` → chama `task.recalculate_status!`

**4. Índice Composto `[task_id, created_at]`:**
```ruby
add_index :task_items, [:task_id, :created_at], if_not_exists: true
```

**Propósito:** Otimizar queries como:
```ruby
task.task_items.order(created_at: :desc) # usado em recalculate_status!
```

### Potential Pitfalls & Prevention

**1. Enum Prefix Conflit (Rails 8.1):**
❌ ERRADO: `enum status: { pending: 'pending', completed: 'completed' }, _prefix: true`
✅ CORRETO: `enum :status, { pending: 'pending', completed: 'completed' }`

**2. Esquecer `if_not_exists: true` em migrations:**
❌ ERRADO: `create_table :task_items do |t|`
✅ CORRETO: `create_table :task_items, if_not_exists: true do |t|`

**3. Usar Float ao invés de Decimal:**
❌ ERRADO: `t.float :hours_worked`
✅ CORRETO: `t.decimal :hours_worked, precision: 10, scale: 2`

**4. Cálculo de Duração Incorreto:**
❌ ERRADO: `(end_time - start_time)` (retorna segundos, não horas)
❌ ERRADO: `(end_time - start_time) / 60` (retorna minutos, não horas)
✅ CORRETO: `(end_time - start_time) / 3600.0` (divide por segundos na hora)

**5. Validação de Task Delivered no Callback Errado:**
❌ ERRADO: `before_create :task_must_not_be_delivered` (só valida na criação)
✅ CORRETO: `validate :task_must_not_be_delivered, on: [:create, :update]` (valida sempre)

**6. Esquecer de Chamar Callbacks em Testes:**
```ruby
# Testar callback explicitamente
it 'calculates hours_worked before save' do
  item = build(:task_item, start_time: '09:00', end_time: '10:30')
  expect { item.save }.to change(item, :hours_worked).from(nil).to(1.5)
end
```

### References

**Epic 4 Technical Spec:**
- [epics.md lines 570-596](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/epics.md#L570-L596) - Story 4.2 requirements
- [epics.md lines 766-793](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/epics.md#L766-L793) - TaskItem schema definition
- [epics.md lines 916-993](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/epics.md#L916-L993) - TaskItem model completo

**Architecture Decisions:**
- [architecture.md lines 99-127](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md#L99-L127) - Modelagem de dados (ARQ17-ARQ27)
- [architecture.md lines 492-498](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md#L492-L498) - Validação tripla camada

**Previous Story (4.1) Implementation:**
- [4-1-criar-model-task-com-validacoes-tripla-camada.md](/home/igor/rails_app/cronos-poc/_bmad-output/implementation-artifacts/4-1-criar-model-task-com-validacoes-tripla-camada.md) - Padrões de implementação estabelecidos

**Code Examples from Epic Spec:**
```ruby
# app/models/task_item.rb (reference from epics.md lines 916-993)
class TaskItem < ApplicationRecord
  belongs_to :task

  validates :task_id, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending completed] }

  validate :end_time_after_start_time
  validate :task_must_not_be_delivered, on: [:create, :update]

  enum :status, { pending: 'pending', completed: 'completed' }

  before_save :calculate_hours_worked
  after_save :update_task_status
  after_destroy :update_task_status

  # NOTA: scopes :pending e :completed NÃO são necessários (são métodos do enum)
  scope :by_task, ->(task_id) { where(task_id: task_id) }
  scope :recent_first, -> { order(created_at: :desc) }

  private

  def end_time_after_start_time
    return unless start_time.present? && end_time.present?

    if end_time <= start_time
      errors.add(:end_time, "deve ser posterior à hora inicial")
    end
  end

  def task_must_not_be_delivered
    return unless task.present?

    if task.delivered?
      errors.add(:base, "Não é possível modificar itens de tarefa já entregue")
    end
  end

  def calculate_hours_worked
    return unless start_time.present? && end_time.present?

    duration_in_seconds = (end_time - start_time)
    self.hours_worked = (duration_in_seconds / 3600.0).round(2)
  end

  def update_task_status
    task.recalculate_status!
  end
end
```

### Definition of Done

- [x] Migration executada sem erros
- [x] Model TaskItem criado com todas as validações e callbacks
- [x] Associação `belongs_to :task` funcionando
- [x] Enum status funcionando (pending, completed)
- [x] Validação `end_time_after_start_time` testada e passando
- [x] Validação `task_must_not_be_delivered` testada e passando (incluindo destroy)
- [x] Callback `calculate_hours_worked` testado e calculando corretamente
- [x] Callback `update_task_status` testado (stub para Story 4.3)
- [x] Factory criada com traits para diferentes cenários
- [x] Testes RSpec criados e passando (100% - 37 testes)
- [ ] Bullet não detecta N+1 queries em testes (não aplicável - sem queries complexas)
- [x] Rubocop não detecta ofensas críticas (corrigido pós-code-review)
- [ ] Schema anotado com `annotate` (não configurado no projeto)
- [x] Associação `has_many :task_items` existe (adicionada na Story 4.1)

## Dev Agent Record

### Agent Model Used
Claude Sonnet 4.5 (claude-sonnet-4-5-20250929)

### Debug Log References
N/A - Implementation completed successfully without issues

### Completion Notes List

**Implementação Concluída:**
- Migration `20260120224736_create_task_items.rb` criada com todos os requisitos AC1-AC8
- Model TaskItem implementado com todas as validações, callbacks e scopes (AC9-AC15)
- Associação `has_many :task_items` existe (adicionada na Story 4.1, não nesta)
- Factory criada com traits: `:pending`, `:completed`, `:long_duration`, `:short_duration`
- Testes abrangentes criados: 37 exemplos cobrindo todos os cenários

**Validações Implementadas:**
- Presence de task, start_time, end_time, status
- Inclusion de status em %w[pending completed]
- Customizada `end_time_after_start_time` - impede end_time <= start_time
- Customizada `task_must_not_be_delivered` - bloqueia create/update/destroy em tasks delivered

**Callbacks Implementados:**
- `before_save :calculate_hours_worked` - cálculo automático de horas trabalhadas
- `after_save :update_task_status` - stub para Story 4.3 (recalculate_status!)
- `after_destroy :update_task_status` - stub para Story 4.3
- `before_destroy :prevent_destroy_if_task_delivered` - previne deleção em tasks delivered

**Scopes Implementados:**
- `by_task(task_id)` - filtra por task
- `recent_first` - ordena por created_at DESC

**Testes Cobertos (37 exemplos, 100% passing):**
- Validations: 16 testes (incluindo destroy)
- Associations: 1 teste
- Enums: 3 testes
- Callbacks: 9 testes
- Scopes: 3 testes
- Database constraints: 1 teste

**Correções Aplicadas (Code Review):**
- ✅ File List corrigido (task.rb não foi modificado nesta story)
- ✅ 7 ofensas do Rubocop corrigidas (agora 0 offenses)
- ✅ Validação destroy adicionada via `before_destroy` callback
- ✅ Teste destroy adicionado para Task delivered
- ✅ Definition of Done atualizado e completo
- ✅ Inconsistência de scopes na documentação corrigida
- ✅ Código limpo e seguindo todos os padrões do projeto

**Nota:** Callback `update_task_status` contém stub intencional para `task.recalculate_status!` que será implementado na Story 4.3 (lógica de status automático).

### File List

**Arquivos Criados:**
- `db/migrate/20260120224736_create_task_items.rb`
- `app/models/task_item.rb`
- `spec/factories/task_items.rb`
- `spec/models/task_item_spec.rb`

**Arquivos Modificados:**
- Nenhum (associação `has_many :task_items` foi adicionada na Story 4.1)

**Observação:** `db/schema.rb` foi atualizado automaticamente pela migration.
