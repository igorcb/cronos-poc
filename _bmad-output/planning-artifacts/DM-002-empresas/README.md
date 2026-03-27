# DM-002: Gestão de Empresas

**Domínio:** Suporte / Cadastro
**Epic Relacionado:** Epic 2
**Status:** Concluído

## Descrição

Domínio responsável pelo cadastro e gerenciamento de empresas (companies) para as quais o usuário presta serviço. Cada empresa possui uma taxa horária (R$/hora) que é utilizada no cálculo de valores monetários das tarefas.

## Entidades

| Entidade | Tabela | Descrição |
|----------|--------|-----------|
| Company | `companies` | Empresa contratante com taxa horária configurável |

### Schema: companies

| Coluna | Tipo | Restrições | Descrição |
|--------|------|------------|-----------|
| `name` | string | NOT NULL | Nome da empresa |
| `hourly_rate` | decimal(10,2) | NOT NULL | Taxa R$/hora |
| `active` | boolean | NOT NULL, default: true | Soft delete flag |
| `created_at` | datetime | auto | Data de criação |
| `updated_at` | datetime | auto | Data de atualização |

### Índices
- `active`

## Regras de Negócio

1. **Soft Delete:** Empresas não são deletadas fisicamente. O campo `active` é alterado para `false` via método `deactivate!`
2. **Scope Active:** `Company.active` retorna apenas empresas com `active: true`
3. **Validações:** `name` e `hourly_rate` são obrigatórios
4. **Restrição de Deleção:** Empresas com time_entries associadas não podem ser hard-deletadas
5. **Taxa Horária:** Usada como base para cálculo de valor em Tasks (`hourly_rate * total_hours`)
6. **Campos Monetários:** Tipo `decimal` com precision: 10, scale: 2 (NUNCA Float)

## Relacionamentos

```
Company
├── has_many :projects
├── has_many :tasks
└── scope :active → where(active: true)
```

## Requisitos Cobertos

### Funcionais
- FR3: CRUD completo de empresas com campos nome e taxa R$/hora

### Arquiteturais
- ARQ22: Soft delete com campo `active`
- ARQ25: Campos monetários com tipo `decimal`
- ARQ43-ARQ44: Naming conventions

## Stories

| Story | Nome | Status |
|-------|------|--------|
| 2.1 | Criar Model e Migration de Companies com Soft Delete | Concluído |
| 2.2 | Implementar CRUD de Companies (Index e New/Create) | Concluído |
| 2.3 | Implementar Edit/Update de Companies | Concluído |
| 2.4 | Implementar Soft Delete de Companies | Concluído |
| 2.5 | Criar Factory e Testes de Model para Company | Concluído |
