---
storyId: '5.20'
epicId: 'DM-005'
status: 'ready-for-development'
createdAt: '2026-05-06'
---

# Story 5.20: KPI Média por Entrega

## Contexto

O usuário acompanha manualmente na planilha "NobeSistemsа - Horas Efetivas" a média de horas por card entregue multiplicada pelo valor/hora da empresa — resultando no ticket médio monetário por entrega do mês. Essa métrica dá uma visão imediata de "quanto vale, em média, cada card que entrego".

Esta story traz esse cálculo para o Cronos POC em dois pontos da interface: o grid de KPIs e ao lado do botão `+` de nova tarefa.

## Fórmula

```
Média por Entrega (R$) = (Horas Entregues no Mês / Qtde de Cards Entregues) × Valor/Hora da Empresa
```

**Referência da planilha:** `=L5*I2*24`
- `L5` = Média de horas por card (ex: 2:12:03)
- `I2` = Valor por hora da empresa (ex: R$ 45,00)
- `×24` = conversão do formato de tempo do Google Sheets para decimal

**Exemplo:** 71 cards entregues, 156:15h totais, R$ 45/h → média 2:12h/card → **R$ 99,03 por entrega**

## Aparições na Interface

### 1. Grid de KPIs — 4º card da linha Entregues

Complementa a Story 5.19, adicionando um 4º card (ou expandindo o grid para 3×4):

```
┌─────────────────┬──────────────────┬─────────────────┬──────────────────────┐
│ Entregas do Mês │ Horas Entregues  │ Valor Entregue  │  Média por Entrega   │
│      71         │    156:15        │  R$ 7.031,25    │      R$ 99,03        │
├─────────────────┴──────────────────┴─────────────────┴──────────────────────┤
│ Tarefas do Mês  │  Horas do Mês    │  Valor do Mês                          │
│ Tarefas Hoje    │  Horas Hoje      │  Valor Hoje                            │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2. Ao lado do botão `+` (nova tarefa)

O mesmo valor exibido na margem direita da mesma linha do botão `+`:

```
[+]                                               Média por Entrega: R$ 99,03
```

Serve como referência rápida antes de criar uma nova tarefa — o usuário sabe o ticket médio do mês sem precisar rolar até os KPIs.

## User Story

**Como** Igor
**Quero** ver o valor médio por card entregue no mês
**Para** entender meu ticket médio e calibrar estimativas de novas tarefas

## Critérios de Aceite

- [ ] **AC1:** Grid de KPIs exibe card "Média por Entrega" na linha Entregues com o valor em R$
- [ ] **AC2:** Cálculo: `(soma horas tasks delivered / qtde tasks delivered) × hourly_rate da empresa`
- [ ] **AC3:** Quando há tasks de múltiplas empresas, usar a média ponderada (cada task usa o hourly_rate da sua empresa)
- [ ] **AC4:** Exibe `R$ 0,00` (ou `—`) quando não há cards entregues no mês
- [ ] **AC5:** Ao lado do botão `+`, na margem direita da mesma linha, exibe "Média por Entrega: R$ XX,XX"
- [ ] **AC6:** Ambas as exibições respeitam os filtros ativos (empresa, projeto, período)
- [ ] **AC7:** Ambas as exibições atualizam via Turbo Stream quando status de task muda para/de `delivered`
- [ ] **AC8:** Specs cobrem o cálculo em `dashboard_kpis_spec.rb`, incluindo caso com zero entregas

## Notas Técnicas

- Cálculo deve ser feito em SQL para evitar N+1: `AVG(hours_worked) * hourly_rate`
- Para múltiplas empresas: `SUM(hours_worked * hourly_rate) / COUNT(tasks)` é mais preciso que `AVG * avg_rate`
- ID sugerido para Turbo Stream: `kpi-media-por-entrega`
- O elemento ao lado do `+` pode ser um partial `_media_por_entrega.html.erb` com `turbo_frame_tag`

## Estimativa

**2 story points (~3h)**
- Query SQL com média ponderada: 1h
- View: card no grid + elemento ao lado do `+`: 1h
- Turbo Streams + specs: 1h
