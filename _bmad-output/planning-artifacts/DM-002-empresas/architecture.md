# Arquitetura - DM-002: Gestão de Empresas

**Domínio:** DM-002-empresas
**Tipo:** Suporte / Cadastro
**Data:** 2025-12-26 (atualizado 2026-03-27)

## Visão Geral

Empresas são entidades de suporte que alimentam o domínio Core (DM-004). Cada empresa possui uma taxa horária que é a base de todo cálculo monetário do sistema. A decisão de soft delete protege dados históricos de faturamento.

## Modelo de Dados

```
┌───────────────────────────────────┐
│            companies              │
├───────────────────────────────────┤
│ id          : bigint PK           │
│ name        : string NOT NULL     │
│ hourly_rate : decimal(10,2) NN    │
│ active      : boolean default:true│
│ created_at  : datetime            │
│ updated_at  : datetime            │
├───────────────────────────────────┤
│ INDEX: active                     │
└───────────────────────────────────┘
        │
        ├── has_many :projects
        └── has_many :tasks
```

## Decisões Arquiteturais

### DA-010: Soft Delete com campo `active`

**Escolha:** Boolean `active` com scope `Company.active`

**Alternativas descartadas:**
- `paranoia` gem (soft delete genérico) — overhead de gem para um único model
- `discard` gem — mesma razão
- Hard delete — perda de dados históricos de faturamento

**Implementação:**
```ruby
class Company < ApplicationRecord
  scope :active, -> { where(active: true) }

  def deactivate!
    update!(active: false)
  end

  def activate!
    update!(active: true)
  end
end
```

**Justificativa:** `hourly_rate` é referenciado em cálculos históricos. Deletar uma empresa invalidaria todos os valores calculados de tasks passadas. Soft delete é a abordagem mais simples que preserva integridade.

### DA-011: Campos Monetários

**Escolha:** `decimal(10,2)` para `hourly_rate`

**Regra absoluta:** NUNCA usar `Float` para valores monetários.

```ruby
# Migration
t.decimal :hourly_rate, precision: 10, scale: 2, null: false
```

**Justificativa:** Float tem problemas de arredondamento (`0.1 + 0.2 != 0.3`). Decimal garante precisão financeira.

### DA-012: Proteção contra Hard Delete

```ruby
def destroy
  if tasks.exists?
    errors.add(:base, "Não é possível deletar empresa com tarefas associadas")
    throw(:abort)
  else
    super
  end
end
```

**Justificativa:** Mesmo com soft delete disponível, previne deleção acidental de dados que são referência para cálculos.

## Fluxo de Dados

```
[Formulário] → CompaniesController → Company Model → PostgreSQL
                    │                      │
                    │              validates :name, :hourly_rate
                    │              scope :active
                    │
                    ▼
              Flash message
              + redirect index
```

## Interface com Outros Domínios

| Domínio Consumidor | Como usa Company |
|--------------------|------------------|
| DM-003 (Projetos) | `Project belongs_to :company` — dropdown de empresas ativas |
| DM-004 (Registro) | `Task belongs_to :company` — `company.hourly_rate` para cálculos |
| DM-005 (Visualização) | Agrupamento por empresa nos totalizadores |
| DM-006 (Filtros) | Filtro por `company_id` |

## Validações (Tripla Camada)

| Camada | Validação | Implementação |
|--------|-----------|---------------|
| DB | NOT NULL em name | `null: false` na migration |
| DB | NOT NULL em hourly_rate | `null: false` na migration |
| Model | Presence | `validates :name, :hourly_rate, presence: true` |
| Client | Required fields | `required: true` no form HTML |
