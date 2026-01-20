# Story 4.1: Criar Model Task com Validações Tripla Camada

Status: backlog

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

**Como** desenvolvedor,
**Quero** criar tabela tasks com validações robustas,
**Para que** dados sejam 100% confiáveis.

## Acceptance Criteria

**Given** que tables companies e projects existem

**When** crio migration CreateTasks

**Then**
1. migration usa `create_table :tasks, if_not_exists: true`
2. possui `t.string :name, null: false`
3. possui `t.references :company, null: false, foreign_key: true, if_not_exists: true`
4. possui `t.references :project, null: false, foreign_key: true, if_not_exists: true`
5. possui `t.date :start_date, null: false`
6. possui `t.date :end_date`
7. possui `t.string :status, null: false, default: 'pending'`
8. possui `t.date :delivery_date`
9. possui `t.decimal :estimated_hours, precision: 10, scale: 2, null: false`
10. possui `t.decimal :validated_hours, precision: 10, scale: 2`
11. possui `t.text :notes`
12. possui timestamps
13. índices criados: `company_id`, `project_id`, `status`, `[company_id, project_id]` com `if_not_exists: true`
14. model Task possui validações: presence de name, company, project, start_date, estimated_hours, status
15. model possui enum status: { pending: 'pending', completed: 'completed', delivered: 'delivered' }
16. model possui validação customizada: project.company_id == company_id
17. `rails db:migrate` executa sem erros

## Tasks / Subtasks

- [ ] Criar migration CreateTasks
  - [ ] Usar `create_table :tasks, if_not_exists: true`
  - [ ] Adicionar coluna `name` (string, null: false)
  - [ ] Adicionar coluna `company_id` (references, null: false, foreign_key: true, if_not_exists: true)
  - [ ] Adicionar coluna `project_id` (references, null: false, foreign_key: true, if_not_exists: true)
  - [ ] Adicionar coluna `start_date` (date, null: false)
  - [ ] Adicionar coluna `end_date` (date)
  - [ ] Adicionar coluna `status` (string, null: false, default: 'pending')
  - [ ] Adicionar coluna `delivery_date` (date)
  - [ ] Adicionar coluna `estimated_hours` (decimal, precision: 10, scale: 2, null: false)
  - [ ] Adicionar coluna `validated_hours` (decimal, precision: 10, scale: 2)
  - [ ] Adicionar coluna `notes` (text)
  - [ ] Adicionar timestamps
  - [ ] Criar índice em `company_id` com `if_not_exists: true`
  - [ ] Criar índice em `project_id` com `if_not_exists: true`
  - [ ] Criar índice em `status` com `if_not_exists: true`
  - [ ] Criar índice composto `[company_id, project_id]` com `if_not_exists: true`
  - [ ] Executar `rails db:migrate`

- [ ] Criar model Task
  - [ ] Adicionar `belongs_to :company`
  - [ ] Adicionar `belongs_to :project`
  - [ ] Adicionar `has_many :task_items, dependent: :destroy`
  - [ ] Adicionar validação `validates :name, presence: true`
  - [ ] Adicionar validação `validates :company_id, presence: true`
  - [ ] Adicionar validação `validates :project_id, presence: true`
  - [ ] Adicionar validação `validates :start_date, presence: true`
  - [ ] Adicionar validação `validates :estimated_hours, presence: true, numericality: { greater_than: 0 }`
  - [ ] Adicionar validação `validates :status, presence: true, inclusion: { in: %w[pending completed delivered] }`
  - [ ] Adicionar enum status: { pending: 'pending', completed: 'completed', delivered: 'delivered' }, _prefix: true
  - [ ] Adicionar validação customizada `project_must_belong_to_company`
  - [ ] Adicionar scopes: `scope :pending`, `scope :completed`, `scope :delivered`, `scope :by_company`, `scope :by_project`

- [ ] Testar migrations
  - [ ] Executar `rails db:migrate`
  - [ ] Verificar se tabela foi criada
  - [ ] Verificar se índices foram criados
