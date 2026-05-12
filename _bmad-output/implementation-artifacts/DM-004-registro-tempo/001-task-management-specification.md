# Epic 4: Task Management System - Especificação Técnica Completa

**Data:** 2026-01-19
**Autor:** Bob (Scrum Master) + Igor (Product Owner)
**Status:** Especificação Aprovada - Aguardando Correct Course
**Padrão de Código:** INGLÊS (schemas, models, campos, métodos)
**Documentação:** PORTUGUÊS (textos explicativos, comentários)

---

## 📋 VISÃO GERAL

Sistema de **gerenciamento de tarefas com tracking de tempo integrado**, substituindo o conceito original de TimeEntries (timesheet simples).

### Mudança Conceitual

**Original (TimeEntries):**
```
Companies → Projects → TimeEntries (registro simples de horas)
```

**Novo (Tasks + TaskItems):**
```
Companies → Projects → Tasks (tarefas gerenciáveis)
                        ├─ Status automático (Pending/Completed/Delivered)
                        ├─ Valores calculados (hourly_rate * hours)
                        ├─ Horas estimadas vs validadas
                        └─ TaskItems (registro granular de horas)
                            ├─ start_time/end_time
                            ├─ Cálculo automático de duração
                            └─ Status que atualiza Task pai
```

---

## 🗄️ SCHEMA DE BANCO DE DADOS

### Tabela: `tasks`

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_tasks.rb
class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks, if_not_exists: true do |t|
      t.string :name, null: false
      t.references :company, null: false, foreign_key: true, if_not_exists: true
      t.references :project, null: false, foreign_key: true, if_not_exists: true
      t.date :start_date, null: false
      t.date :end_date
      t.string :status, null: false, default: 'pending'
      t.date :delivery_date
      t.decimal :estimated_hours, precision: 10, scale: 2, null: false
      t.decimal :validated_hours, precision: 10, scale: 2
      t.text :notes

      t.timestamps
    end

    add_index :tasks, :company_id, if_not_exists: true
    add_index :tasks, :project_id, if_not_exists: true
    add_index :tasks, :status, if_not_exists: true
    add_index :tasks, [:company_id, :project_id], if_not_exists: true
  end
end
```

**Campos:**
- `name` (string, obrigatório): Nome da tarefa
- `company_id` (integer, obrigatório): FK para companies
- `project_id` (integer, obrigatório): FK para projects
- `start_date` (date, obrigatório): Data de início (manual)
- `end_date` (date, opcional): Data de término (automática quando completed)
- `status` (string, obrigatório, default: 'pending'): Status da tarefa
- `delivery_date` (date, opcional): Data de entrega ao cliente (automática quando delivered)
- `estimated_hours` (decimal, obrigatório): Horas estimadas (manual)
- `validated_hours` (decimal, opcional): Horas reais (calculado)
- `notes` (text, opcional): Observações gerais

---

### Tabela: `task_items`

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_task_items.rb
class CreateTaskItems < ActiveRecord::Migration[8.1]
  def change
    create_table :task_items, if_not_exists: true do |t|
      t.references :task, null: false, foreign_key: true, if_not_exists: true
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.decimal :hours_worked, precision: 10, scale: 2, null: false
      t.string :status, null: false, default: 'pending'

      t.timestamps
    end

    add_index :task_items, :task_id, if_not_exists: true
    add_index :task_items, :status, if_not_exists: true
    add_index :task_items, [:task_id, :created_at], if_not_exists: true
  end
end
```

**Campos:**
- `task_id` (integer, obrigatório): FK para tasks
- `start_time` (time, obrigatório): Hora de início do trabalho
- `end_time` (time, obrigatório): Hora de término do trabalho
- `hours_worked` (decimal, obrigatório): Duração calculada (end_time - start_time)
- `status` (string, obrigatório, default: 'pending'): Status do item

---

## 🏗️ MODELS

### Model: Task

```ruby
# app/models/task.rb
class Task < ApplicationRecord
  # ============================================================================
  # ASSOCIAÇÕES
  # ============================================================================
  belongs_to :company
  belongs_to :project
  has_many :task_items, dependent: :destroy

  # ============================================================================
  # VALIDAÇÕES
  # ============================================================================
  validates :name, presence: true
  validates :company_id, presence: true
  validates :project_id, presence: true
  validates :start_date, presence: true
  validates :estimated_hours, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending completed delivered] }

  # Validação customizada: project deve pertencer à company
  validate :project_must_belong_to_company

  # ============================================================================
  # ENUMS
  # ============================================================================
  enum status: {
    pending: 'pending',
    completed: 'completed',
    delivered: 'delivered'
  }, _prefix: true

  # ============================================================================
  # CALLBACKS
  # ============================================================================
  before_save :update_end_date, if: :status_changed_to_completed?
  before_save :update_delivery_date, if: :status_changed_to_delivered?
  after_save :recalculate_validated_hours

  # ============================================================================
  # SCOPES
  # ============================================================================
  scope :pending, -> { where(status: 'pending') }
  scope :completed, -> { where(status: 'completed') }
  scope :delivered, -> { where(status: 'delivered') }
  scope :by_company, ->(company_id) { where(company_id: company_id) }
  scope :by_project, ->(project_id) { where(project_id: project_id) }

  # ============================================================================
  # MÉTODOS PÚBLICOS
  # ============================================================================

  # Calcula total de horas trabalhadas (soma dos TaskItems)
  def total_hours
    task_items.sum(:hours_worked)
  end

  # Calcula valor da tarefa (company.hourly_rate * total_hours)
  def calculated_value
    company.hourly_rate * total_hours
  end

  # Recalcula status baseado no último TaskItem criado
  def recalculate_status!
    return if delivered? # Não recalcula se já está delivered (imutável)

    latest_item = task_items.order(created_at: :desc).first
    return unless latest_item

    new_status = latest_item.completed? ? 'completed' : 'pending'
    update_column(:status, new_status) if status != new_status
  end

  # ============================================================================
  # MÉTODOS PRIVADOS
  # ============================================================================
  private

  # Validação: project deve pertencer à company selecionada
  def project_must_belong_to_company
    return unless project.present? && company.present?

    if project.company_id != company_id
      errors.add(:project, "deve pertencer à empresa selecionada")
    end
  end

  # Callback: atualiza end_date quando muda para completed
  def status_changed_to_completed?
    status == 'completed' && status_changed?
  end

  def update_end_date
    self.end_date = Date.today
  end

  # Callback: atualiza delivery_date quando muda para delivered
  def status_changed_to_delivered?
    status == 'delivered' && status_changed?
  end

  def update_delivery_date
    self.delivery_date = Date.today
  end

  # Callback: recalcula validated_hours após cada save
  def recalculate_validated_hours
    update_column(:validated_hours, total_hours)
  end
end
```

---

### Model: TaskItem

```ruby
# app/models/task_item.rb
class TaskItem < ApplicationRecord
  # ============================================================================
  # ASSOCIAÇÕES
  # ============================================================================
  belongs_to :task

  # ============================================================================
  # VALIDAÇÕES
  # ============================================================================
  validates :task_id, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending completed] }

  validate :end_time_after_start_time
  validate :task_must_not_be_delivered, on: [:create, :update]

  # ============================================================================
  # ENUMS
  # ============================================================================
  enum status: {
    pending: 'pending',
    completed: 'completed'
  }, _prefix: true

  # ============================================================================
  # CALLBACKS
  # ============================================================================
  before_save :calculate_hours_worked
  after_save :update_task_status
  after_destroy :update_task_status

  # ============================================================================
  # SCOPES
  # ============================================================================
  scope :pending, -> { where(status: 'pending') }
  scope :completed, -> { where(status: 'completed') }
  scope :by_task, ->(task_id) { where(task_id: task_id) }
  scope :recent_first, -> { order(created_at: :desc) }

  # ============================================================================
  # MÉTODOS PRIVADOS
  # ============================================================================
  private

  # Validação: end_time deve ser posterior à start_time
  def end_time_after_start_time
    return unless start_time.present? && end_time.present?

    if end_time <= start_time
      errors.add(:end_time, "deve ser posterior à hora inicial")
    end
  end

  # Validação: não pode modificar TaskItem de Task delivered
  def task_must_not_be_delivered
    return unless task.present?

    if task.delivered?
      errors.add(:base, "Não é possível modificar itens de tarefa já entregue")
    end
  end

  # Callback: calcula hours_worked automaticamente
  def calculate_hours_worked
    return unless start_time.present? && end_time.present?

    duration_in_seconds = (end_time - start_time)
    self.hours_worked = (duration_in_seconds / 3600.0).round(2)
  end

  # Callback: atualiza status da Task pai
  def update_task_status
    task.recalculate_status!
  end
end
```

---

## 📊 REGRAS DE NEGÓCIO

### 1. Relacionamento Task → Company + Project

**Regra:** Task pertence diretamente a Company E Project, com validação de consistência.

**Validação:**
```ruby
project.company_id == task.company_id
```

**Comportamento do Form:**
```javascript
// Quando seleciona Company no dropdown
onCompanyChange(company_id) {
  // Recarrega dropdown de Projects mostrando apenas:
  // Project.where(company_id: company_id).active.order(:name)
}
```

**Exemplo Válido:**
```ruby
company_a = Company.find(1)
project_x = Project.find(5) # project_x.company_id == 1

task = Task.create(
  name: "Implement Report",
  company: company_a,
  project: project_x  # ✅ Mesmo company_id
)
# ✅ SUCESSO
```

**Exemplo Inválido:**
```ruby
company_a = Company.find(1)
project_y = Project.find(10) # project_y.company_id == 2

task = Task.create(
  name: "Implement Report",
  company: company_a,
  project: project_y  # ❌ company_id diferente
)
# ❌ ERRO: "Project deve pertencer à empresa selecionada"
```

---

### 2. Status Automático "Completed"

**Regra:** Task muda para "completed" quando o **último TaskItem CRIADO** (created_at DESC) estiver com status "completed".

**Algoritmo:**
```ruby
def recalculate_status!
  return if delivered? # Não recalcula se já está delivered

  latest_item = task_items.order(created_at: :desc).first
  return unless latest_item

  new_status = latest_item.completed? ? 'completed' : 'pending'
  update_column(:status, new_status) if status != new_status
end
```

**Exemplo 1: Finalizando Task**
```ruby
task = Task.create(name: "Implement Report", status: 'pending', ...)

# Cria 3 TaskItems
TaskItem.create(task: task, start_time: '08:00', end_time: '08:50', status: 'pending')
# created_at: 2026-01-19 09:00

TaskItem.create(task: task, start_time: '10:00', end_time: '10:45', status: 'pending')
# created_at: 2026-01-19 10:00

TaskItem.create(task: task, start_time: '13:00', end_time: '13:27', status: 'pending')
# created_at: 2026-01-19 11:00 ← ÚLTIMO CRIADO

# Task.status = 'pending' (porque último criado está pending)

# Finaliza o último item criado (11:00)
item_3 = TaskItem.last
item_3.update(status: 'completed')

# Task.status = 'completed' (porque último criado está completed)
```

**Exemplo 2: Reabertura de Task**
```ruby
task = Task.find(1) # Status: completed
# 3 TaskItems, todos completed (último criado: 11:00)

# Cria novo TaskItem pending
TaskItem.create(task: task, start_time: '15:00', end_time: '15:30', status: 'pending')
# created_at: 2026-01-19 12:00 ← NOVO ÚLTIMO CRIADO

# Task.status = 'pending' (porque último criado está pending)
```

**Exemplo 3: Mantém Completed**
```ruby
task = Task.find(1) # Status: completed
# 3 TaskItems, todos completed (último criado: 11:00)

# Cria novo TaskItem JÁ COMPLETED
TaskItem.create(task: task, start_time: '16:00', end_time: '16:45', status: 'completed')
# created_at: 2026-01-19 13:00 ← NOVO ÚLTIMO CRIADO

# Task.status = 'completed' (porque último criado está completed)
```

---

### 3. Status Manual "Delivered" (Imutável)

**Regra:** Status "delivered" é definido manualmente via botão/ícone e torna a Task **read-only**.

**Comportamento:**
```ruby
# Botão "Mark as Delivered"
def mark_as_delivered
  task.update!(
    status: 'delivered',
    delivery_date: Date.today
  )
end
```

**Restrições:**
```ruby
# Não pode criar novos TaskItems
TaskItem.create(task: task_delivered, ...)
# ❌ ERRO: "Não é possível modificar itens de tarefa já entregue"

# Não pode editar TaskItems existentes
task_item.update(status: 'completed')
# ❌ ERRO: "Não é possível modificar itens de tarefa já entregue"

# Não pode deletar TaskItems
task_item.destroy
# ❌ ERRO: "Não é possível modificar itens de tarefa já entregue"

# Status "delivered" é FINAL (não pode voltar para completed ou pending)
task_delivered.recalculate_status!
# → Não faz nada (return if delivered?)
```

**Fluxo de Status:**
```
pending ←→ completed → delivered (FINAL)
   ↑           ↑
   └───────────┘
   (automático via TaskItems)
```

---

### 4. Campos de Data

**start_date: MANUAL**
```ruby
# Usuário define ao criar a Task
task = Task.create(
  name: "Implement Report",
  start_date: Date.new(2026, 1, 10),  # Manual
  ...
)
```

**end_date: AUTOMÁTICA**
```ruby
# Atualiza automaticamente quando status → completed
before_save :update_end_date, if: :status_changed_to_completed?

def update_end_date
  self.end_date = Date.today
end

# Exemplo:
task.update(status: 'completed')
# → task.end_date = Date.today (2026-01-19)
```

**delivery_date: AUTOMÁTICA**
```ruby
# Atualiza automaticamente quando status → delivered
before_save :update_delivery_date, if: :status_changed_to_delivered?

def update_delivery_date
  self.delivery_date = Date.today
end
```

---

### 5. Cálculos Automáticos

**hours_worked (TaskItem):**
```ruby
# Calculado automaticamente antes de save
before_save :calculate_hours_worked

def calculate_hours_worked
  return unless start_time.present? && end_time.present?

  duration_in_seconds = (end_time - start_time)
  self.hours_worked = (duration_in_seconds / 3600.0).round(2)
end

# Exemplo:
TaskItem.create(start_time: '08:00', end_time: '10:30', ...)
# → hours_worked = 2.5
```

**validated_hours (Task):**
```ruby
# Atualiza após cada save
after_save :recalculate_validated_hours

def recalculate_validated_hours
  update_column(:validated_hours, total_hours)
end

def total_hours
  task_items.sum(:hours_worked)
end

# Exemplo:
task.task_items.sum(:hours_worked) # => 5.75
task.validated_hours # => 5.75 (atualizado automaticamente)
```

**calculated_value (Task):**
```ruby
# Método virtual (não persiste no banco)
def calculated_value
  company.hourly_rate * total_hours
end

# Exemplo:
task.company.hourly_rate # => 45.00
task.total_hours # => 5.75
task.calculated_value # => 258.75 (45.00 * 5.75)
```

---

## 🎯 CASOS DE USO COMPLETOS

### Caso de Uso 1: Criar Task e Registrar Horas

```ruby
# 1. Criar Task
company = Company.find_by(name: "Company A")
project = company.projects.find_by(name: "Project X")

task = Task.create!(
  name: "Implement Sales Report",
  company: company,
  project: project,
  start_date: Date.new(2026, 1, 10),
  estimated_hours: 8.0,
  status: 'pending'
)
# Status: pending
# end_date: nil
# validated_hours: 0.0
# calculated_value: 0.0

# 2. Registrar primeira hora de trabalho
TaskItem.create!(
  task: task,
  start_time: Time.parse('08:00'),
  end_time: Time.parse('09:30'),
  status: 'pending'
)
# hours_worked: 1.5 (calculado automaticamente)
# Task.status: pending (último item criado está pending)
# Task.validated_hours: 1.5
# Task.calculated_value: 67.50 (45.00 * 1.5)

# 3. Registrar segunda hora (já completed)
TaskItem.create!(
  task: task,
  start_time: Time.parse('10:00'),
  end_time: Time.parse('12:15'),
  status: 'completed'
)
# hours_worked: 2.25
# Task.status: completed (último item criado está completed)
# Task.end_date: 2026-01-19 (atualizado automaticamente)
# Task.validated_hours: 3.75 (1.5 + 2.25)
# Task.calculated_value: 168.75 (45.00 * 3.75)

# 4. Adicionar hora extra (reabre Task)
TaskItem.create!(
  task: task,
  start_time: Time.parse('14:00'),
  end_time: Time.parse('15:00'),
  status: 'pending'
)
# hours_worked: 1.0
# Task.status: pending (último item criado está pending)
# Task.validated_hours: 4.75 (1.5 + 2.25 + 1.0)
# Task.calculated_value: 213.75 (45.00 * 4.75)

# 5. Finalizar última hora
item_3 = TaskItem.last
item_3.update!(status: 'completed')
# Task.status: completed (último item criado está completed)
# Task.end_date: 2026-01-19 (atualizado novamente)

# 6. Marcar como Delivered
task.update!(status: 'delivered')
# Task.status: delivered
# Task.delivery_date: 2026-01-19
# Task agora é READ-ONLY

# 7. Tentar adicionar hora (ERRO)
TaskItem.create(task: task, ...)
# ❌ ActiveRecord::RecordInvalid:
#    "Não é possível modificar itens de tarefa já entregue"
```

---

### Caso de Uso 2: Validação de Consistência Company/Project

```ruby
# Cenário 1: Form com dropdowns (caminho feliz)
company_a = Company.find(1)
projects_from_company_a = company_a.projects # Dropdown filtrado

task = Task.create(
  company: company_a,
  project: projects_from_company_a.first  # ✅ Consistente
)
# ✅ SUCESSO

# Cenário 2: Console/API bypass (validação protege)
company_a = Company.find(1)
project_from_other_company = Project.find(99) # company_id: 2

task = Task.create(
  company: company_a,
  project: project_from_other_company  # ❌ Inconsistente
)
# ❌ ActiveRecord::RecordInvalid:
#    "Project deve pertencer à empresa selecionada"
```

---

### Caso de Uso 3: Comparação Horas Estimadas vs Validadas

```ruby
task = Task.create(
  name: "Implement Feature X",
  estimated_hours: 5.0,  # Estimativa inicial
  ...
)

# Trabalho real registrado
TaskItem.create(task: task, start_time: '08:00', end_time: '10:00', status: 'completed')
TaskItem.create(task: task, start_time: '10:00', end_time: '13:30', status: 'completed')

# Relatório
task.estimated_hours  # => 5.0
task.validated_hours  # => 5.5 (2.0 + 3.5)
task.calculated_value # => 247.50 (45.00 * 5.5)

# Análise
difference = task.validated_hours - task.estimated_hours # => 0.5
percentage = (difference / task.estimated_hours) * 100   # => 10%
# Resultado: 10% acima do estimado
```

---

## 🚨 IMPACTO EM EPICS 4-8

### Epic 4: Registro de Entradas de Tempo
**Status:** 🚨 **REFAZER COMPLETO**

**Original:**
- 6 stories focadas em TimeEntry model simples
- Concern Calculable para cálculos
- Form simples (project, start_time, end_time)

**Novo:**
- Precisa de 2 models (Task + TaskItem)
- Relacionamento duplo (company + project)
- Status automático complexo
- Validações de imutabilidade
- Funcionalidade "Mark as Delivered"

**Estimativa:** Epic 4 passará de 6 stories para ~10-12 stories

---

### Epic 5: Visualização e Totalizadores
**Status:** ⚠️ **REVISAR PARCIAL**

**Mudanças:**
- Index deve mostrar Tasks (não TimeEntries)
- Totalizadores agora são por Task (não por entrada)
- ViewComponent precisa mostrar TaskItems agregados
- Turbo Streams para atualizar Task + TaskItems

**Estimativa:** +2-3 stories adicionais para lidar com agregação

---

### Epic 6: Filtros Dinâmicos
**Status:** ⚠️ **REVISAR PARCIAL**

**Mudanças:**
- Filtros por company E project (antes só project)
- Status agora tem 3 valores (pending/completed/delivered)
- Recalcular totalizadores por Task (não por entry)

**Estimativa:** +1-2 stories adicionais

---

### Epic 7: Edição e Correção de Entradas
**Status:** 🚨 **REFAZER COMPLETO**

**Mudanças:**
- Editar Task (campos adicionais: start_date, estimated_hours, notes)
- Editar TaskItems (start_time, end_time)
- Validação de Task delivered (read-only)
- Destroy precisa considerar status "delivered"
- System tests para fluxo Task → TaskItems → Delivered

**Estimativa:** Epic 7 passará de 3 stories para ~5-6 stories

---

### Epic 8: Responsividade e Experiência Mobile
**Status:** ⚠️ **REVISAR LEVE**

**Mudanças:**
- Form de Task mais complexo (company + project dropdowns)
- Lista de TaskItems por Task
- Botão "Mark as Delivered" mobile-friendly

**Estimativa:** +1 story adicional

---

## 📊 RESUMO DE IMPACTO

| Epic | Status Original | Status Novo | Stories Original | Stories Estimado | Impacto |
|------|----------------|-------------|------------------|------------------|---------|
| Epic 4 | 6 stories | 🚨 REFAZER | 6 | 10-12 | **+67-100%** |
| Epic 5 | 5 stories | ⚠️ REVISAR | 5 | 7-8 | +40-60% |
| Epic 6 | 4 stories | ⚠️ REVISAR | 4 | 5-6 | +25-50% |
| Epic 7 | 3 stories | 🚨 REFAZER | 3 | 5-6 | **+67-100%** |
| Epic 8 | 4 stories | ⚠️ REVISAR | 4 | 5 | +25% |
| **TOTAL** | **22 stories** | - | **22** | **32-37** | **+45-68%** |

---

## ✅ PRÓXIMOS PASSOS

**Bob (Scrum Master):** "Igor, este documento captura toda a especificação técnica que conversamos. Agora vou:"

1. ✅ **Executar `*CC` (Correct Course)** com este documento como input
2. ✅ **Analisar impacto detalhado** em cada story de Epics 4-8
3. ✅ **Revisar Architecture.md** para adicionar decisões de Task/TaskItem
4. ✅ **Revisar PRD** para atualizar requisitos de negócio
5. ✅ **Propor plano de ação:**
   - Opção A: Refazer Epics 4-8 completos
   - Opção B: Epic 4 como Task Management + Epic 4.5 simplificado
   - Opção C: Implementar incremental (Epic 4 simples → Epic 4.5 avançado)

---

**Documento aprovado por:**
- ✅ Igor (Product Owner)
- ✅ Bob (Scrum Master)
- ✅ Charlie (Senior Dev) - Revisão técnica
- ✅ Alice (Product Owner) - Validação de requisitos

**Data de aprovação:** 2026-01-19
**Próximo passo:** Executar Correct Course Workflow
