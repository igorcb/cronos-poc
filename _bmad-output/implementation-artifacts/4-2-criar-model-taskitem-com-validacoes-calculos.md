# Story 4.2: Criar Model TaskItem com Validações e Cálculos

Status: backlog

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

**Como** desenvolvedor,
**Quero** criar tabela task_items para registro granular de horas,
**Para que** cada período de trabalho seja registrado individualmente.

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

- [ ] Criar migration CreateTaskItems
  - [ ] Usar `create_table :task_items, if_not_exists: true`
  - [ ] Adicionar coluna `task_id` (references, null: false, foreign_key: true, if_not_exists: true)
  - [ ] Adicionar coluna `start_time` (time, null: false)
  - [ ] Adicionar coluna `end_time` (time, null: false)
  - [ ] Adicionar coluna `hours_worked` (decimal, precision: 10, scale: 2, null: false)
  - [ ] Adicionar coluna `status` (string, null: false, default: 'pending')
  - [ ] Adicionar timestamps
  - [ ] Criar índice em `task_id` com `if_not_exists: true`
  - [ ] Criar índice em `status` com `if_not_exists: true`
  - [ ] Criar índice composto `[task_id, created_at]` com `if_not_exists: true`
  - [ ] Executar `rails db:migrate`

- [ ] Criar model TaskItem
  - [ ] Adicionar `belongs_to :task`
  - [ ] Adicionar validação `validates :task_id, presence: true`
  - [ ] Adicionar validação `validates :start_time, presence: true`
  - [ ] Adicionar validação `validates :end_time, presence: true`
  - [ ] Adicionar validação `validates :status, presence: true, inclusion: { in: %w[pending completed] }`
  - [ ] Adicionar validação customizada `end_time_after_start_time`
  - [ ] Adicionar validação customizada `task_must_not_be_delivered`
  - [ ] Adicionar enum status: { pending: 'pending', completed: 'completed' }, _prefix: true
  - [ ] Adicionar callback `before_save :calculate_hours_worked`
  - [ ] Adicionar callback `after_save :update_task_status`
  - [ ] Adicionar callback `after_destroy :update_task_status`
  - [ ] Implementar método `calculate_hours_worked` (private)
  - [ ] Implementar método `end_time_after_start_time` (private)
  - [ ] Implementar método `task_must_not_be_delivered` (private)
  - [ ] Implementar método `update_task_status` (private)
  - [ ] Adicionar scopes: `scope :pending`, `scope :completed`, `scope :by_task`, `scope :recent_first`

- [ ] Testar migrations
  - [ ] Executar `rails db:migrate`
  - [ ] Verificar se tabela foi criada
  - [ ] Verificar se índices foram criados
