# Arquitetura - DM-010: Consistência de Métricas e Nomenclatura

**Domínio:** DM-010-consistencia-metricas
**Tipo:** Correção / Qualidade de Dados
**Data:** 2026-06-17

## Visão Geral

Domínio de correção pontual. A divergência ocorre porque Dashboard e Resumo Diário
usam queries distintas sobre entidades diferentes (`Task` vs `TaskItem`) para representar
o mesmo conceito — quantidade de tarefas no mês. A correção unifica o critério de contagem
e a nomenclatura.

## Diagnóstico da Divergência

```
Dashboard                          Resumo Diário
─────────────────────              ─────────────────────
KPI: "Tasks Mês"                   KPI: "Cards no mês"
Valor: 61                          Valor: 81
                │                              │
                ▼                              ▼
  Task.where(start_date: mes)     TaskItem.where(work_date: mes)
  .count                          .count   ← conta apontamentos!
                │                              │
                └──────── divergem ────────────┘
                          +20 registros
```

**Causa raiz:** Resumo Diário conta `task_items` (apontamentos diários de tempo).
Uma task com trabalho registrado em 3 dias diferentes gera 3 task_items,
inflando o KPI em relação à contagem de tasks distintas do Dashboard.

## Decisão Arquitetural

### DA-100: Critério único de contagem — Tasks distintas

**Escolha:** Ambos os KPIs devem contar `Task.distinct` com apontamento no período,
não `TaskItem.count`.

**Query correta para Resumo Diário:**
```ruby
# Antes (errado — conta task_items)
@cards_no_mes = TaskItem.where(work_date: mes_range).count

# Depois (correto — conta tasks distintas com apontamento no mês)
@tarefas_no_mes = Task.joins(:task_items)
                      .where(task_items: { work_date: mes_range })
                      .distinct
                      .count
```

**Query do Dashboard (referência — não alterar):**
```ruby
Task.where(start_date: mes_range).count
```

> **Atenção:** Verificar se o critério do Dashboard usa `start_date` da Task
> ou `work_date` do TaskItem. Se diferentes, alinhar para o mesmo campo antes de unificar.

### DA-101: Padronização de nomenclatura

**Escolha:** Rótulo "Tarefas do mês" em todos os KPIs de contagem de tarefas.

| Arquivo | Rótulo atual | Rótulo novo |
|---------|-------------|-------------|
| `app/views/dashboard/index.html.erb` | Tasks Mês | Tarefas do mês |
| `app/views/resumo_diario/index.html.erb` | Cards no mês | Tarefas do mês |

## Interface com Outros Domínios

| Domínio | Relação |
|---------|---------|
| DM-005 (Visualização & Totalizadores) | KPIs do Dashboard foram criados aqui; alteração de rótulo impacta as views deste domínio |
| DM-004 (Registro de Tempo) | Task e TaskItem são as entidades corrigidas |

## Metas de Qualidade

| Critério | Meta |
|----------|------|
| Consistência | Dashboard e Resumo Diário exibem o mesmo valor para o mesmo mês |
| Nomenclatura | Zero rótulos em inglês ou jargão técnico nos KPIs de contagem |
| Cobertura de testes | Spec validando igualdade dos dois KPIs para o mesmo período |
