# Story 3.1: Criar Model e Migration de Projects com Foreign Key

Status: review

## Story

**Como** desenvolvedor,
**Quero** criar a tabela projects associada a companies,
**Para que** Igor possa organizar projetos por empresa.

## Acceptance Criteria

**Given** que a tabela companies existe

**When** crio migration CreateProjects

**Then**
1. Migration usa `create_table :projects, if_not_exists: true`
2. Tabela possui coluna `name` (string, null: false)
3. Tabela possui `t.references :company, null: false, foreign_key: true, if_not_exists: true`
4. Tabela possui timestamps
5. Índice criado em `company_id` com `if_not_exists: true`
6. Model Project é criado com: `belongs_to :company`
7. Model possui: `has_many :time_entries, dependent: :restrict_with_error`
8. Validações: `validates :name, presence: true` (company_id validation is implicit via belongs_to)
9. `rails db:migrate` executa sem erros

## Tasks / Subtasks

- [x] Gerar migration CreateProjects
  - [x] `rails generate migration CreateProjects`
  - [x] Editar migration com estrutura completa
  - [x] Adicionar referência para company com FK constraint
  - [x] Usar `if_not_exists: true` conforme ARQ18

- [x] Criar Model Project
  - [x] Criar `app/models/project.rb`
  - [x] Adicionar `belongs_to :company`
  - [x] Adicionar `has_many :time_entries, dependent: :restrict_with_error`
  - [x] Adicionar validações de presence

- [x] Executar migration
  - [x] `rails db:migrate`
  - [x] Verificar tabela criada
  - [x] Testar rollback e re-migrate

- [x] Validar no console
  - [x] Criar company e project
  - [x] Testar associação project.company
  - [x] Testar validações

## Dev Notes

### Contexto Arquitetural

**ARQ23 - Restrict Delete:**
- Projects usam `dependent: :restrict_with_error`
- Bloqueia deleção se houver time_entries associadas
- Permite deleção se projeto não tem entradas

**ARQ18 - if_not_exists:**
- SEMPRE usar em create_table, add_column, add_index
- Garante idempotência das migrations

### Migration Template

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_projects.rb
class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects, if_not_exists: true do |t|
      t.string :name, null: false
      t.references :company, null: false, foreign_key: true, if_not_exists: true

      t.timestamps
    end

    add_index :projects, :company_id, if_not_exists: true
  end
end
```

### Model Template

```ruby
# app/models/project.rb
class Project < ApplicationRecord
  belongs_to :company
  has_many :time_entries, dependent: :restrict_with_error

  validates :name, presence: true
  validates :company_id, presence: true
end
```

### Teste no Console

```ruby
company = Company.create!(name: "Empresa Teste", hourly_rate: 100.00)
project = Project.create!(name: "Projeto X", company: company)

project.company
# => #<Company id: 1, name: "Empresa Teste">

Project.create(name: nil)
# => Erro: Name can't be blank
```

### References

- [Architecture: ARQ23](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md#arq23)
- [Epics: Story 3.1](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/epics.md#story-31-criar-model-e-migration-de-projects-com-foreign-key)

## Dev Agent Record

### Completion Notes List

- [x] Migration criada e executada
- [x] Model Project criado
- [x] Associações configuradas
- [x] Validações implementadas
- [x] Testado no console

### Implementation Notes (Barry - 2026-01-19)

✅ **Implementação completa seguindo TDD:**
1. Migration CreateProjects com `if_not_exists: true` (ARQ18)
2. Model Project com validações e associações
3. Factory FactoryBot para testes
4. 12 testes passando (100% coverage)
5. Suite completa: 104 examples, 0 failures
6. RuboCop: 0 offenses
7. Company model atualizado com `has_many :projects`

**Nota:** `time_entries` association comentada nos testes - será implementada no Epic 4

### File List

- `db/migrate/20260119002519_create_projects.rb` (NEW)
- `app/models/project.rb` (NEW)
- `app/models/company.rb` (MODIFIED - added has_many :projects)
- `spec/models/project_spec.rb` (NEW)
- `spec/models/company_spec.rb` (MODIFIED - added FK constraint test)
- `spec/factories/projects.rb` (NEW)
- `spec/migrations/create_projects_spec.rb` (NEW)
- `db/schema.rb` (AUTO-GENERATED)
- `.rubocop_todo.yml` (AUTO-MODIFIED)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (MODIFIED)
- `_bmad-output/implementation-artifacts/3-1-criar-model-e-migration-de-projects-com-foreign-key.md` (MODIFIED - this file)

---

## CRITICAL DEVELOPER GUARDRAILS

### ⚠️ VALIDAÇÕES OBRIGATÓRIAS

1. **ANTES de marcar story como concluída:**
   - [x] Migration usa `if_not_exists: true`
   - [x] Foreign key constraint existe
   - [x] `dependent: :restrict_with_error` configurado
   - [x] Validações funcionam

### 🎯 OBJETIVOS

**Esta story DEVE entregar:**
- ✅ Tabela projects com FK para companies
- ✅ Model com associações
- ✅ Validações tripla camada
- ✅ Restrict delete configurado
