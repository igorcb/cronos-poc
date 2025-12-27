# Story 3.1: Criar Model e Migration de Projects com Foreign Key

Status: ready-for-dev

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
8. Validações: `validates :name, :company_id, presence: true`
9. `rails db:migrate` executa sem erros

## Tasks / Subtasks

- [ ] Gerar migration CreateProjects
  - [ ] `rails generate migration CreateProjects`
  - [ ] Editar migration com estrutura completa
  - [ ] Adicionar referência para company com FK constraint
  - [ ] Usar `if_not_exists: true` conforme ARQ18

- [ ] Criar Model Project
  - [ ] Criar `app/models/project.rb`
  - [ ] Adicionar `belongs_to :company`
  - [ ] Adicionar `has_many :time_entries, dependent: :restrict_with_error`
  - [ ] Adicionar validações de presence

- [ ] Executar migration
  - [ ] `rails db:migrate`
  - [ ] Verificar tabela criada
  - [ ] Testar rollback e re-migrate

- [ ] Validar no console
  - [ ] Criar company e project
  - [ ] Testar associação project.company
  - [ ] Testar validações

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

- [ ] Migration criada e executada
- [ ] Model Project criado
- [ ] Associações configuradas
- [ ] Validações implementadas
- [ ] Testado no console

### File List

_A ser preenchido pelo Dev Agent_

---

## CRITICAL DEVELOPER GUARDRAILS

### ⚠️ VALIDAÇÕES OBRIGATÓRIAS

1. **ANTES de marcar story como concluída:**
   - [ ] Migration usa `if_not_exists: true`
   - [ ] Foreign key constraint existe
   - [ ] `dependent: :restrict_with_error` configurado
   - [ ] Validações funcionam

### 🎯 OBJETIVOS

**Esta story DEVE entregar:**
- ✅ Tabela projects com FK para companies
- ✅ Model com associações
- ✅ Validações tripla camada
- ✅ Restrict delete configurado
