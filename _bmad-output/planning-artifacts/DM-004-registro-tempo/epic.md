# Epic DM-004: Registro de Tempo (Task Management System)

**Domínio:** DM-004-registro-tempo
**Tipo:** Core / Principal
**Status:** Em Progresso
**Prioridade:** Crítica (coração do produto)

## Objetivo

Permitir que Igor registre e gerencie tarefas com tracking automático de tempo, status inteligente e cálculos precisos de horas e valores monetários. Este é o domínio que substitui a planilha Excel.

## Valor de Negócio

Este é o **core do produto** — a razão de existir do Cronos POC. Entrega:
- Registro de tempo em ~30 segundos (vs 1-2 min na planilha)
- Cálculos 100% automáticos e confiáveis (horas e R$)
- Status automático que elimina gestão manual
- Dados confiáveis que empresas contratantes aceitam sem questionamento

**Momento de valor:** Igor registra 3h para Tributário, e instantaneamente vê: "3h × R$ 45 = R$ 135,00". Sem fórmula, sem conferência, sem medo.

## Dependências

- **Predecessores:** DM-002 (Empresas — `hourly_rate`), DM-003 (Projetos — classificação)
- **Sucessores:** DM-005 (Visualização), DM-006 (Filtros), DM-007 (Mobile)

## Mudança Arquitetural

O Epic 4 foi **reformulado** após a retrospectiva do Epic 3:

```
ANTES: Companies → Projects → TimeEntries (registro simples)
AGORA: Companies → Projects → Tasks (gerenciáveis) → TaskItems (granular)
```

**Justificativa:** Tasks permitem agrupar múltiplos períodos de trabalho, status automático, e visão de "tarefa como unidade de trabalho" em vez de "linha de timesheet".

## Decisões Arquiteturais

| Decisão | Escolha | Justificativa |
|---------|---------|---------------|
| Modelo | Tasks + TaskItems | Granularidade + agrupamento lógico |
| Status | Automático via callbacks | Elimina gestão manual, menos erros |
| Cálculos | `before_save` + `after_save` | Dados sempre consistentes |
| Validação | Tripla camada (DB + Model + Client) | Zero tolerância a dados inválidos |
| Imutabilidade | `delivered` é estado final | Integridade para faturamento |
| Selector | Stimulus + fetch JSON | UX fluida sem reload |
| Monetário | `decimal(10,2)` + desnormalização | Precisão + performance |

## Critérios de Aceite do Épico

### Registro (Epic 4)
- [ ] Criar task com name, company, project, start_date, estimated_hours
- [ ] Project dropdown filtra por company selecionada (< 300ms)
- [ ] Validação: project deve pertencer à company
- [ ] TaskItem calcula `hours_worked` automaticamente
- [ ] Task status atualiza automaticamente baseado no último TaskItem
- [ ] Task `delivered` é imutável (não aceita novos TaskItems)
- [ ] `calculated_value` = `company.hourly_rate * total_hours`
- [ ] Testes RSpec de Task e TaskItem passam 100%

### Edição e Correção (Epic 7)
- [ ] Edit/Update de tasks e task_items funcional
- [ ] Destroy com confirmação do usuário
- [ ] Recálculo automático de totais após edição/deleção
- [ ] Testes de system cobrem fluxo completo (criar → editar → deletar)

## Stories

### Registro e Gestão (originalmente Epic 4)

| # | Arquivo | Nome |
|---|---------|------|
| 001 | `001-task-management-specification.md` | Especificação Técnica do Task Management |
| 002 | `002-criar-model-task-com-validacoes-tripla-camada.md` | Criar Model Task com Validações Tripla Camada |
| 003 | `003-criar-model-taskitem-com-validacoes-calculos.md` | Criar Model TaskItem com Validações e Cálculos |
| 004 | `004-implementar-logica-status-automatico-calculos.md` | Implementar Lógica de Status Automático e Cálculos |
| 005 | `005-implementar-crud-de-tasks-new-create.md` | Implementar CRUD de Tasks (New/Create) |
| 006 | `006-implementar-project-selector-dinamico-stimulus.md` | Implementar Project Selector Dinâmico (Stimulus) |
| 007 | `007-criar-factories-testes-para-task-taskitem.md` | Criar Factories e Testes para Task e TaskItem |

### Edição e Correção (originalmente Epic 7)

| # | Arquivo | Nome |
|---|---------|------|
| 008 | `008-implementar-edit-update-de-timeentries.md` | Implementar Edit/Update de Entries |
| 009 | `009-implementar-destroy-de-timeentries-com-confirmacao.md` | Implementar Destroy com Confirmação |
| 010 | `010-criar-testes-de-system-para-fluxo-completo.md` | Criar Testes de System para Fluxo Completo |

### Retrospectiva

| # | Arquivo | Nome |
|---|---------|------|
| 011 | `011-retro-2026-01-26.md` | Retrospectiva Epic 4 |

## Requisitos Rastreados

- FR1, FR2, FR5, FR6, FR16, FR17
- ARQ17-ARQ21, ARQ24-ARQ27, ARQ40-ARQ42
- NFR10, NFR11, NFR12, NFR13
