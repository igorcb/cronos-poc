# Epic DM-002: Gestão de Empresas

**Domínio:** DM-002-empresas
**Tipo:** Suporte / Cadastro
**Status:** Concluído
**Prioridade:** Alta (dependência direta do domínio Core)

## Objetivo

Permitir que Igor cadastre, edite e gerencie as empresas para as quais trabalha, cada uma com sua taxa horária (R$/hora), garantindo que dados históricos sejam preservados via soft delete.

## Valor de Negócio

Empresas são a unidade fundamental de faturamento. Sem elas, não é possível:
- Calcular valores monetários das tarefas (`hourly_rate * hours`)
- Agrupar horas por empresa para fechamento mensal
- Gerar dados confiáveis para envio às contratantes

**Momento de valor:** Quando Igor cadastra "Tributário - R$ 45/hora" e sabe que todo cálculo futuro será automático e preciso.

## Dependências

- **Predecessores:** DM-001 (Infraestrutura e Auth)
- **Sucessores:** DM-003 (Projetos), DM-004 (Registro de Tempo)

## Decisões Arquiteturais

| Decisão | Escolha | Justificativa |
|---------|---------|---------------|
| Deleção | Soft delete (`active` boolean) | Preservar histórico e integridade referencial |
| Monetário | `decimal(10,2)` | Precisão financeira, nunca Float |
| Scope | `Company.active` | Evitar que empresas inativas poluam dropdowns |
| Proteção | Bloqueia hard delete se tem tasks | Integridade dos dados de faturamento |

## Critérios de Aceite do Épico

- [ ] CRUD completo de empresas funcional (index, new, create, edit, update)
- [ ] Soft delete via `deactivate!` funciona corretamente
- [ ] Empresas desativadas não aparecem na listagem nem em dropdowns
- [ ] Validações de `name` e `hourly_rate` impedem dados inválidos
- [ ] `hourly_rate` armazenado como `decimal(10,2)`
- [ ] Testes RSpec do model passam 100%
- [ ] Flash messages de feedback exibidas corretamente

## Stories

| # | Arquivo | Nome |
|---|---------|------|
| 001 | `001-criar-model-e-migration-de-companies-com-soft-delete.md` | Criar Model e Migration com Soft Delete |
| 002 | `002-implementar-crud-de-companies-index-e-new-create.md` | Implementar CRUD (Index e New/Create) |
| 003 | `003-implementar-edit-update-de-companies.md` | Implementar Edit/Update |
| 004 | `004-implementar-soft-delete-de-companies.md` | Implementar Soft Delete |
| 005 | `005-criar-factory-e-testes-de-model-para-company.md` | Criar Factory e Testes |

## Requisitos Rastreados

- FR3
- ARQ22, ARQ25, ARQ43-ARQ44
