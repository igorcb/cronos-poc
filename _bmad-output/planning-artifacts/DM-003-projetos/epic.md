# Epic DM-003: Gestão de Projetos

**Domínio:** DM-003-projetos
**Tipo:** Suporte / Cadastro
**Status:** Concluído
**Prioridade:** Alta (dependência direta do domínio Core)

## Objetivo

Permitir que Igor cadastre e organize projetos vinculados às empresas, criando a segunda camada de organização do trabalho que facilita a classificação e filtro de tarefas.

## Valor de Negócio

Projetos dão granularidade ao registro de tempo. Sem eles, Igor saberia apenas "trabalhei X horas para Tributário", mas não "trabalhei X horas no projeto tributario-api vs tributario-frontend". Isso permite:
- Detalhamento por projeto no fechamento mensal
- Filtros mais precisos para análise de tempo
- Organização alinhada com a estrutura real de trabalho

**Momento de valor:** Quando Igor seleciona "Tributário" e o dropdown filtra automaticamente apenas os projetos dessa empresa.

## Dependências

- **Predecessores:** DM-002 (Empresas — `belongs_to :company`)
- **Sucessores:** DM-004 (Registro de Tempo — `belongs_to :project`)

## Decisões Arquiteturais

| Decisão | Escolha | Justificativa |
|---------|---------|---------------|
| Deleção | Hard delete (com proteção) | Projetos sem tasks podem ser removidos |
| Proteção | `dependent: :restrict_with_error` | Impede deleção se tem tasks associadas |
| FK | `company_id NOT NULL` | Todo projeto obrigatoriamente pertence a uma empresa |
| Dropdown | Filtra por `Company.active` | Não permite vincular projetos a empresas inativas |

## Critérios de Aceite do Épico

- [ ] CRUD completo de projetos funcional (index, new, create, edit, update, destroy)
- [ ] Todo projeto pertence a uma empresa (`belongs_to :company`)
- [ ] Dropdown de empresas mostra apenas `Company.active`
- [ ] Deleção bloqueada se projeto tem tasks associadas (mensagem clara)
- [ ] Deleção permitida se projeto não tem tasks
- [ ] Validações de `name` e `company_id` impedem dados inválidos
- [ ] Testes RSpec do model passam 100%

## Stories

| # | Arquivo | Nome |
|---|---------|------|
| 001 | `001-criar-model-e-migration-de-projects-com-foreign-key.md` | Criar Model e Migration com Foreign Key |
| 002 | `002-implementar-crud-de-projects-index-e-new-create.md` | Implementar CRUD (Index e New/Create) |
| 003 | `003-implementar-edit-update-e-destroy-de-projects.md` | Implementar Edit/Update e Destroy |
| 004 | `004-criar-factory-e-testes-para-project.md` | Criar Factory e Testes |
| 005 | `005-retro-2026-01-19.md` | Retrospectiva Epic 3 |

## Requisitos Rastreados

- FR4
- ARQ23
