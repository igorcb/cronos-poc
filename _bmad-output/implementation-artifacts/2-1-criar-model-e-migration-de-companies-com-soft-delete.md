# Story 2.1: Criar Model e Migration de Companies com Soft Delete

Status: ready-for-dev

## Story

**Como** desenvolvedor,
**Quero** criar a tabela companies com campos necessários,
**Para que** Igor possa cadastrar as empresas que trabalha.

## Acceptance Criteria

**Given** que a autenticação está funcional

**When** crio migration CreateCompanies

**Then**
1. Migration usa `create_table :companies, if_not_exists: true`
2. Tabela possui coluna `name` (string, null: false)
3. Tabela possui coluna `hourly_rate` (decimal, precision: 10, scale: 2, null: false)
4. Tabela possui coluna `active` (boolean, default: true, null: false)
5. Tabela possui timestamps (created_at, updated_at)
6. Índice criado em `active` com `if_not_exists: true`
7. Model Company é criado com validações: `validates :name, :hourly_rate, presence: true`
8. Model possui scopes: `scope :active, -> { where(active: true) }`
9. Model possui métodos `deactivate!` e `activate!`
10. `rails db:migrate` executa sem erros

## Tasks / Subtasks

- [ ] Gerar migration CreateCompanies (AC: #1-6)
  - [ ] `rails generate migration CreateCompanies`
  - [ ] Editar migration com estrutura completa
  - [ ] Adicionar colunas: name, hourly_rate, active, timestamps
  - [ ] Garantir uso de `if_not_exists: true` conforme ARQ18
  - [ ] Adicionar índice em `active` com `if_not_exists: true`

- [ ] Criar Model Company (AC: #7-9)
  - [ ] Criar `app/models/company.rb`
  - [ ] Adicionar validações de presence para name e hourly_rate
  - [ ] Adicionar validação numérica para hourly_rate (> 0)
  - [ ] Adicionar scope `active`
  - [ ] Implementar método `deactivate!`
  - [ ] Implementar método `activate!`
  - [ ] Adicionar override de `destroy` para prevenir deleção com time_entries

- [ ] Executar e validar migration (AC: #10)
  - [ ] `rails db:migrate`
  - [ ] Verificar tabela criada no PostgreSQL
  - [ ] `rails db:rollback` (testar reversibilidade)
  - [ ] `rails db:migrate` novamente

- [ ] Validar model no console
  - [ ] `rails console`
  - [ ] Criar empresa válida: `Company.create!(name: "Teste", hourly_rate: 100.00)`
  - [ ] Testar validações: `Company.create(name: nil)` deve falhar
  - [ ] Testar scope: `Company.active` retorna apenas ativas
  - [ ] Testar deactivate: `company.deactivate!` muda active para false

## Dev Notes

### Contexto Arquitetural

**ARQ22 - Soft Delete para Companies:**
- Companies implementam soft delete com campo `active` (boolean, default: true)
- Empresas nunca são deletadas permanentemente para preservar histórico
- `hourly_rate` é crítico para cálculos históricos de TimeEntries

**ARQ18 - SEMPRE usar `if_not_exists: true`:**
- CRÍTICO: Migrations devem usar `if_not_exists: true` em tabelas, colunas e índices
- Garante idempotência e previne erros em re-execuções

**ARQ25 - Campos monetários:**
- Usar tipo `decimal` com precision: 10, scale: 2
- NUNCA usar Float para valores monetários (perda de precisão)

### Migration Template

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_companies.rb
class CreateCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :companies, if_not_exists: true do |t|
      t.string :name, null: false
      t.decimal :hourly_rate, precision: 10, scale: 2, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :companies, :active, if_not_exists: true
  end
end
```

### Model Template

```ruby
# app/models/company.rb
class Company < ApplicationRecord
  # Validações
  validates :name, presence: true
  validates :hourly_rate, presence: true, numericality: { greater_than: 0 }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  # Soft delete
  def deactivate!
    update!(active: false)
  end

  def activate!
    update!(active: true)
  end

  # Override destroy para prevenir deleção acidental
  def destroy
    if time_entries.exists?
      errors.add(:base, "Não é possível deletar empresa com entradas de tempo associadas. Use deactivate! para desativar.")
      throw(:abort)
    else
      super
    end
  end
end
```

### Validações Obrigatórias

**Database Constraints (Primeira Camada):**
- `null: false` em name, hourly_rate, active
- `default: true` em active
- Tipo decimal com precision correta

**Model Validations (Segunda Camada):**
- Presence de name e hourly_rate
- Numericality de hourly_rate > 0

**Rationale:**
- Tripla camada garante dados sempre consistentes
- Soft delete preserva histórico de faturamento
- Validação numérica previne taxas negativas ou zero

### Comandos Úteis

```bash
# Gerar migration
rails generate migration CreateCompanies

# Executar migration
rails db:migrate

# Verificar status
rails db:migrate:status

# Testar rollback
rails db:rollback

# Console Rails
rails console

# Verificar schema
rails db:schema:dump
```

### Testes Manuais no Console

```ruby
# Criar empresa válida
company = Company.create!(name: "Empresa A", hourly_rate: 150.50)
# => #<Company id: 1, name: "Empresa A", hourly_rate: 150.5, active: true>

# Testar validação de presence
Company.create(name: nil)
# => Erro: Name can't be blank

# Testar validação numérica
Company.create(name: "Teste", hourly_rate: -10)
# => Erro: Hourly rate must be greater than 0

# Testar soft delete
company.deactivate!
company.active
# => false

Company.active
# => [] (não inclui empresa desativada)

company.activate!
company.active
# => true
```

### References

- [Architecture: Decisão 1.2 - Soft Delete](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md#decisão-12-estratégia-de-dependent-destroy)
- [Architecture: ARQ22 - Companies Soft Delete](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md#arq22)
- [Architecture: ARQ18 - if_not_exists](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md#arq18)
- [Architecture: ARQ25 - Campos Monetários](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md#arq25)
- [Epics: Story 2.1](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/epics.md#story-21-criar-model-e-migration-de-companies-com-soft-delete)

## Dev Agent Record

### Agent Model Used

_A ser preenchido pelo Dev Agent durante execução_

### Debug Log References

_A ser preenchido pelo Dev Agent se houver problemas_

### Completion Notes List

_A ser preenchido pelo Dev Agent ao finalizar:_
- [ ] Migration criada e executada com sucesso
- [ ] Tabela companies existe no database
- [ ] Model Company criado com validações
- [ ] Scopes active/inactive funcionais
- [ ] Métodos deactivate!/activate! testados
- [ ] Validações testadas no console

### File List

_A ser preenchido pelo Dev Agent com arquivos criados/modificados_

---

## CRITICAL DEVELOPER GUARDRAILS

### ⚠️ VALIDAÇÕES OBRIGATÓRIAS

1. **ANTES de marcar story como concluída, VERIFICAR:**
   - [ ] Migration usa `create_table :companies, if_not_exists: true`
   - [ ] Índice usa `if_not_exists: true`
   - [ ] Campo `hourly_rate` é decimal(10,2), NÃO float
   - [ ] Campo `active` tem default: true
   - [ ] Model possui validações de presence
   - [ ] Scopes active/inactive funcionam
   - [ ] Métodos deactivate!/activate! funcionam
   - [ ] `rails db:migrate` executa sem erros

2. **NÃO PROSSEGUIR para Story 2.2 se:**
   - Tabela companies não foi criada
   - Model Company não tem validações
   - Soft delete não está funcionando
   - Algum campo está usando Float ao invés de Decimal

### 🎯 OBJETIVOS DESTA STORY

**Esta story DEVE entregar:**
- ✅ Tabela companies no database
- ✅ Model Company com validações
- ✅ Soft delete funcional
- ✅ Scopes active/inactive
- ✅ Validação tripla camada (DB + Model)

**Esta story NÃO implementa:**
- ❌ Controllers ou views (Story 2.2)
- ❌ Factories ou testes RSpec (Story 2.5)
- ❌ CRUD completo (Stories 2.2, 2.3, 2.4)

### 📝 PADRÃO ARQ18 - CRITICAL

**SEMPRE usar `if_not_exists: true`:**

```ruby
# ✅ CORRETO
create_table :companies, if_not_exists: true do |t|
  # ...
end

add_index :companies, :active, if_not_exists: true

# ❌ ERRADO (vai falhar se rodar migration duas vezes)
create_table :companies do |t|
  # ...
end

add_index :companies, :active
```

**SEMPRE usar decimal para dinheiro:**

```ruby
# ✅ CORRETO
t.decimal :hourly_rate, precision: 10, scale: 2, null: false

# ❌ ERRADO (perda de precisão)
t.float :hourly_rate
```
