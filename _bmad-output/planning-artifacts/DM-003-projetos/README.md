# DM-003: Gestão de Projetos

**Domínio:** Suporte / Cadastro
**Epic Relacionado:** Epic 3
**Status:** Concluído

## Descrição

Domínio responsável pelo cadastro e organização de projetos vinculados a empresas. Projetos são a segunda camada de organização do trabalho, permitindo que o usuário classifique suas tarefas por empresa e projeto.

## Entidades

| Entidade | Tabela | Descrição |
|----------|--------|-----------|
| Project | `projects` | Projeto associado a uma empresa |

### Schema: projects

| Coluna | Tipo | Restrições | Descrição |
|--------|------|------------|-----------|
| `name` | string | NOT NULL | Nome do projeto |
| `company_id` | integer | NOT NULL, FK | Empresa associada |
| `created_at` | datetime | auto | Data de criação |
| `updated_at` | datetime | auto | Data de atualização |

### Índices
- `company_id`

## Regras de Negócio

1. **Associação Obrigatória:** Todo projeto deve pertencer a uma empresa (`belongs_to :company`)
2. **Proteção contra Deleção:** Projetos com time_entries associadas não podem ser deletados (`dependent: :restrict_with_error`)
3. **Validações:** `name` e `company_id` são obrigatórios
4. **Filtro por Empresa Ativa:** Dropdowns de criação mostram apenas `Company.active`
5. **Deleção Permitida:** Se projeto NÃO tem time_entries, pode ser deletado fisicamente

## Relacionamentos

```
Project
├── belongs_to :company
├── has_many :tasks, dependent: :restrict_with_error
└── has_many :task_items (through: :tasks)
```

## Requisitos Cobertos

### Funcionais
- FR4: CRUD completo de projetos com campos nome e empresa associada (FK)

### Arquiteturais
- ARQ23: `dependent: :restrict_with_error` para prevenir deleção acidental

## Stories

| Story | Nome | Status |
|-------|------|--------|
| 3.1 | Criar Model e Migration de Projects com Foreign Key | Concluído |
| 3.2 | Implementar CRUD de Projects (Index e New/Create) | Concluído |
| 3.3 | Implementar Edit/Update e Destroy de Projects | Concluído |
| 3.4 | Criar Factory e Testes para Project | Concluído |
| 3.5 | Retrospectiva Epic 3 (2026-01-19) | Concluído |
