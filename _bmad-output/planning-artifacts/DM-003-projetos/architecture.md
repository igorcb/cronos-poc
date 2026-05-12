# Arquitetura - DM-003: Gestão de Projetos

**Domínio:** DM-003-projetos
**Tipo:** Suporte / Cadastro
**Data:** 2025-12-26 (atualizado 2026-03-27)

## Visão Geral

Projetos são a segunda camada de organização hierárquica: `Company → Project → Task`. Todo projeto pertence a uma empresa, e essa associação é validada em cascata até o nível de Task.

## Modelo de Dados

```
┌───────────────────────────────────┐
│             projects              │
├───────────────────────────────────┤
│ id          : bigint PK           │
│ name        : string NOT NULL     │
│ company_id  : bigint FK NOT NULL  │
│ created_at  : datetime            │
│ updated_at  : datetime            │
├───────────────────────────────────┤
│ INDEX: company_id                 │
│ FK: company_id → companies(id)    │
└───────────────────────────────────┘
        │
        ├── belongs_to :company
        └── has_many :tasks (restrict_with_error)
```

## Decisões Arquiteturais

### DA-020: Estratégia de Deleção — Restrict with Error

**Escolha:** `dependent: :restrict_with_error`

**Alternativas descartadas:**
- `dependent: :destroy` — cascata perigosa, deletaria tasks e dados de faturamento
- Soft delete — desnecessário, projetos são menos críticos que empresas
- `dependent: :nullify` — tasks ficariam órfãs, sem contexto

**Implementação:**
```ruby
class Project < ApplicationRecord
  belongs_to :company
  has_many :tasks, dependent: :restrict_with_error

  validates :name, :company_id, presence: true
end
```

**Comportamento:**
- Projeto com tasks → erro claro: "Não é possível deletar projeto com entradas de tempo"
- Projeto sem tasks → deleção física permitida

**Justificativa:** Projetos sem tasks são seguros para deletar. Projetos com tasks são dados de referência para faturamento e não devem ser removidos.

### DA-021: Validação de Integridade Company-Project

A relação `Project → Company` é a base da validação em cascata:

```
Company(id:1) ─── Project(id:5, company_id:1) ─── Task(company_id:1, project_id:5) ✅
Company(id:1) ─── Project(id:10, company_id:2) ─── Task(company_id:1, project_id:10) ❌
```

A validação `project_must_belong_to_company` no model Task (DM-004) garante essa consistência.

### DA-022: Dropdown Filtrado por Empresa Ativa

Formulários de criação/edição mostram apenas empresas ativas:

```ruby
# No controller ou helper
Company.active.order(:name)
```

Isso garante que novos projetos não sejam vinculados a empresas desativadas.

## Fluxo de Dados

```
[Formulário]                   [Dropdown]
    │                              │
    │  name: "tributario-api"      │  Company.active.order(:name)
    │  company_id: 1               │
    ▼                              ▼
ProjectsController ──▶ Project Model ──▶ PostgreSQL
                           │
                   validates :name
                   validates :company_id
                   belongs_to :company
```

## Interface com Outros Domínios

| Domínio Consumidor | Como usa Project |
|--------------------|------------------|
| DM-004 (Registro) | `Task belongs_to :project` — dropdown filtrado por company |
| DM-005 (Visualização) | Nome do projeto na listagem de tasks |
| DM-006 (Filtros) | Filtro por `project_id` |

## Validações (Tripla Camada)

| Camada | Validação | Implementação |
|--------|-----------|---------------|
| DB | NOT NULL em name | `null: false` na migration |
| DB | FK company_id | `foreign_key: true` na migration |
| Model | Presence | `validates :name, :company_id, presence: true` |
| Client | Required + dropdown | Campos obrigatórios no form |
