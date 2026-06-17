---
storyId: '10.1'
epicId: 'DM-010'
status: 'ready_for_dev'
createdAt: '2026-06-17'
---

# Story 10.1: Corrigir Contagem Divergente de Tarefas entre Dashboard e Resumo Diário

## Contexto

Durante inspeção da aplicação em produção (17/06/2026) foi identificada divergência entre
dois KPIs que representam o mesmo conceito — quantidade de tarefas no mês:

| Tela | KPI | Valor (Junho/2026) |
|------|-----|--------------------|
| Dashboard | Tasks Mês | **61** |
| Resumo Diário | Cards no mês | **81** |

A causa raiz é que o Resumo Diário conta `task_items` (apontamentos diários de tempo),
enquanto o Dashboard conta `tasks` distintas. Uma task com apontamentos em 3 dias gera
3 task_items, inflando o KPI do Resumo Diário em +20.

## User Story

**Como** Igor
**Quero** que o número de tarefas do mês seja o mesmo no Dashboard e no Resumo Diário
**Para** poder confiar nos dados e reconciliar as duas telas sem ambiguidade

## Critérios de Aceite

- [ ] **AC1:** Dashboard "Tarefas do mês" e Resumo Diário "Tarefas do mês" exibem o mesmo valor para Junho/2026
- [ ] **AC2:** O valor representa tasks distintas — não task_items duplicados por dia
- [ ] **AC3:** Ao trocar o mês no filtro do Resumo Diário, o KPI atualiza corretamente mantendo a mesma lógica de contagem
- [ ] **AC4:** Spec valida que os dois KPIs retornam o mesmo valor para o mesmo período
- [ ] **AC5:** Nenhuma regressão nos demais totalizadores (Horas no mês, Valor no mês)

## Notas Técnicas

**Query atual no Resumo Diário (incorreta):**
```ruby
# Conta task_items — gera duplicidade
@cards_no_mes = TaskItem.where(work_date: mes_range).count
```

**Query corrigida:**
```ruby
# Conta tasks distintas com apontamento no mês
@tarefas_no_mes = Task.joins(:task_items)
                      .where(task_items: { work_date: mes_range })
                      .distinct
                      .count
```

> Verificar se o Dashboard usa `start_date` da Task ou `work_date` do TaskItem.
> Alinhar o campo de referência antes de unificar para garantir AC1.

- Controller afetado: `ResumoDiarioController` (ou equivalente)
- View afetada: `app/views/resumo_diario/index.html.erb`
- Specs a criar/atualizar: `spec/requests/resumo_diario_spec.rb` ou equivalente

## Estimativa

**3 story points (~4h)**
- Diagnóstico e correção da query: 1h
- Atualização da view (rótulo + valor): 1h
- Specs (contagem consistente + regressão): 2h
