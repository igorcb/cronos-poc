# Story 10.1: Corrigir Contagem Divergente de Tarefas entre Dashboard e Resumo Diário

**Status:** done
**Domínio:** DM-010-consistencia-metricas
**Data:** 2026-06-17
**Epic:** Epic 10 — Consistência de Métricas e Nomenclatura
**Story ID:** 10.1
**Story Key:** 10-1-corrigir-contagem-divergente-tarefas-mes

---

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

---

## História do Usuário

**Como** Igor,
**Quero** que o número de tarefas do mês seja o mesmo no Dashboard e no Resumo Diário,
**Para** poder confiar nos dados e reconciliar as duas telas sem ambiguidade.

---

## Critérios de Aceite

- [x] **AC1:** Dashboard e Resumo Diário exibem o mesmo valor de "Tarefas do mês" para o mesmo período
- [x] **AC2:** O valor representa tasks distintas — não task_items duplicados por dia
- [x] **AC3:** Ao trocar o mês no filtro do Resumo Diário, o KPI atualiza corretamente mantendo a mesma lógica de contagem
- [x] **AC4:** Spec valida que os dois KPIs retornam o mesmo valor para o mesmo período
- [x] **AC5:** Nenhuma regressão nos demais totalizadores (Horas no mês, Valor no mês)

---

## Análise Técnica

### Causa raiz

```ruby
# Resumo Diário — query atual (INCORRETA — conta task_items)
@cards_no_mes = TaskItem.where(work_date: mes_range).count
# Resultado: 81 (conta cada apontamento diário)

# Dashboard — query atual (CORRETA — conta tasks distintas)
@tasks_mes = Task.where(start_date: mes_range).count
# Resultado: 61
```

### Correção

```ruby
# Resumo Diário — query corrigida (tasks distintas com apontamento no mês)
@tarefas_no_mes = Task.joins(:task_items)
                      .where(task_items: { work_date: mes_range })
                      .distinct
                      .count
```

> **Atenção:** Verificar se Dashboard usa `start_date` da Task ou `work_date` do TaskItem.
> Alinhar o campo de referência para garantir que AC1 seja satisfeito.

---

## Arquivos a Modificar

| Arquivo | Ação |
|---------|------|
| Controller do Resumo Diário | Corrigir query de `@cards_no_mes` para contar tasks distintas |
| `app/views/resumo_diario/index.html.erb` | Atualizar variável referenciada na view |
| Spec do Resumo Diário | Adicionar/atualizar spec validando contagem de tasks distintas |

---

## Testes

- [ ] KPI exibe tasks distintas, não task_items (uma task com 3 apontamentos conta como 1)
- [ ] Valor do KPI no Resumo Diário bate com o valor do Dashboard para o mesmo mês
- [ ] Trocar mês no filtro recalcula corretamente
- [ ] Sem regressão nos KPIs de Horas no mês e Valor no mês

---

## Dependências

- `TaskItem` com campo `work_date` — **já existe**
- `Task.joins(:task_items)` — associação já estabelecida

---

## Estimativa

**3 story points** (~4h) — diagnóstico + correção de query (1h) + view (1h) + specs (2h)
