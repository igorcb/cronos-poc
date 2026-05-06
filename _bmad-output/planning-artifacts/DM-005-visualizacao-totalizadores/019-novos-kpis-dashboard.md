---
storyId: '5.19'
epicId: 'DM-005'
status: 'done'
createdAt: '2026-05-06'
---

# Story 5.19: Novos KPIs do Dashboard

## Contexto

O dashboard atual exibe KPIs de totais gerais (tarefas, horas e valor do mês) e um bloco de total do dia. O usuário precisa distinguir visualmente o que foi **entregue** (status `delivered`) do que está em aberto — atualmente esses dados não são separados na interface.

Esta story adiciona uma segunda linha de KPIs focada exclusivamente nas tarefas com status `delivered`, completando o grid de 3×3 proposto.

## Layout Proposto

```
┌─────────────────┬──────────────────┬─────────────────┐
│ Entregas do Mês │ Horas Entregues  │ Valor Entregue  │
│  (qtde tasks    │  (soma hours     │  (soma valor    │
│   delivered)    │   delivered)     │   delivered)    │
├─────────────────┼──────────────────┼─────────────────┤
│ Tarefas do Mês  │  Horas do Mês    │  Valor do Mês   │
│  (todas tasks   │  (todas horas    │  (todo valor    │
│   do mês)       │   do mês)        │   do mês)       │
├─────────────────┼──────────────────┼─────────────────┤
│ Tarefas Hoje    │   Horas Hoje     │   Valor Hoje    │
│  (tasks com     │  (horas do dia   │  (valor do dia  │
│   entry hoje)   │   atual)         │   atual)        │
└─────────────────┴──────────────────┴─────────────────┘
```

**Linha 1 — Entregues (novo):** filtra apenas tasks com `status = delivered` no mês corrente.
**Linha 2 — Mês (existente):** totais gerais do mês (todas as tasks).
**Linha 3 — Hoje (existente):** totais do dia atual.

## Definição dos KPIs

### Linha 1 — Entregues do Mês (novos)

| KPI | Nome exibido | Descrição | Cálculo |
|-----|-------------|-----------|---------|
| K1 | **Entregas do Mês** | Qtde de tasks com status `delivered` no mês | `Task.where(status: :delivered, month: current_month).count` |
| K2 | **Horas Entregues** | Soma de horas das tasks delivered | `SUM(hours_worked)` das tasks com status delivered |
| K3 | **Valor Entregue** | Valor monetário das tasks delivered | `SUM(hours_worked × company.hourly_rate)` das tasks delivered |

### Linha 2 — Totais do Mês (existentes, mantidos)

| KPI | Nome exibido |
|-----|-------------|
| K4 | **Tarefas do Mês** |
| K5 | **Horas do Mês** |
| K6 | **Valor do Mês** |

### Linha 3 — Hoje (existentes, mantidos)

| KPI | Nome exibido |
|-----|-------------|
| K7 | **Tarefas Hoje** |
| K8 | **Horas Hoje** |
| K9 | **Valor Hoje** |

## User Story

**Como** Igor
**Quero** ver no dashboard quantas tarefas entreguei no mês, com suas horas e valor correspondentes
**Para** saber rapidamente o que já foi faturável sem precisar filtrar manualmente

## Critérios de Aceite

- [ ] **AC1:** Dashboard exibe linha "Entregues" acima da linha "Mês" com 3 cards: Entregas do Mês, Horas Entregues, Valor Entregue
- [ ] **AC2:** "Entregas do Mês" exibe a contagem de tasks com `status = delivered` no mês atual
- [ ] **AC3:** "Horas Entregues" exibe a soma de `hours_worked` das tasks delivered do mês
- [ ] **AC4:** "Valor Entregue" exibe o valor monetário calculado das tasks delivered do mês (formatado em R$)
- [ ] **AC5:** Os 3 novos KPIs respeitam os filtros ativos (empresa, projeto, período) — mesma base de query dos demais totalizadores
- [ ] **AC6:** Os 3 novos KPIs atualizam via Turbo Stream quando uma task tem status alterado para/de `delivered` (mesmo comportamento dos KPIs existentes no `TasksController#create`)
- [ ] **AC7:** Layout responsivo — em mobile os 9 cards empilham corretamente (3 linhas × 3 colunas → 1 coluna no mobile)
- [ ] **AC8:** Specs cobrem os 3 novos KPIs em `dashboard_kpis_spec.rb`

## Notas Técnicas

- Seguir padrão dos KPIs existentes: ViewComponent ou partial `_kpis.html.erb`
- Query base: mesma utilizada pelos totalizadores do mês, com filtro adicional `status: :delivered`
- Turbo Stream: adicionar `turbo_stream.replace` para os 3 novos IDs de card no `TasksController` (path modal e path normal)
- Evitar N+1: entregar cálculo via `select` com `SUM` no SQL, não Ruby
- IDs sugeridos: `kpi-entregas-mes`, `kpi-horas-entregues`, `kpi-valor-entregue`

## Estimativa

**2 story points (~4h)**
- Query + cálculo: 1h
- View/componente: 1h
- Turbo Streams + filtros: 1h
- Specs: 1h
