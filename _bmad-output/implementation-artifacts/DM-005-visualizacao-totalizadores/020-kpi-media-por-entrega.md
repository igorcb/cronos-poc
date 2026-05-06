# Story 5.20: KPI Média por Entrega (R$) no Grid e ao Lado do Botão +

**Status:** ready-for-dev
**Domínio:** DM-005-visualizacao-totalizadores
**Data:** 2026-05-06
**Epic:** Epic 5 — Visualização & Dashboard
**Story ID:** 5.20
**Story Key:** 5-20-kpi-media-por-entrega

---

## Contexto

O usuário acompanha manualmente na planilha o ticket médio por card entregue (`=L5*I2*24` — média de horas por card × valor/hora). Essa métrica serve como referência para calibrar estimativas de novas tarefas e avaliar produtividade do mês.

Esta story traz esse cálculo para o Cronos POC em dois pontos da interface:
1. **Grid de KPIs** — 4º card da linha "Entregues" (ao lado dos 3 criados na story 5.19)
2. **Ao lado do botão `+`** — referência rápida sem precisar rolar até os KPIs

---

## História do Usuário

**Como** Igor,
**Quero** ver o valor médio por card entregue no mês em destaque no dashboard,
**Para** entender meu ticket médio e calibrar estimativas de novas tarefas sem consultar planilha.

---

## Fórmula

```
Média por Entrega (R$) = Valor Entregue no Mês ÷ Qtde de Cards Entregues
                       = SUM(validated_hours × hourly_rate) / COUNT(tasks delivered)
```

**Exemplo:** 71 cards entregues, 156:15h totais, R$ 45/h → **R$ 99,03 por entrega**

> Para múltiplas empresas com hourly_rates diferentes: `SUM(validated_hours × hourly_rate) / COUNT(tasks)` é mais preciso que `AVG(hours) × AVG(rate)`.

---

## Layout Proposto

```
┌─────────────────┬──────────────────┬─────────────────┬──────────────────────┐
│ Entregas do Mês │ Horas Entregues  │ Valor Entregue  │  Média por Entrega   │
│      71         │    156:15        │  R$ 7.031,25    │      R$ 99,03        │
├─────────────────┴──────────────────┴─────────────────┴──────────────────────┤
│ Tarefas do Mês  │  Horas do Mês    │  Valor do Mês                          │
│ Tarefas Hoje    │  Horas Hoje      │  Valor Hoje                            │
└─────────────────────────────────────────────────────────────────────────────┘

[+ Nova Tarefa]                              Média por Entrega: R$ 99,03
```

---

## Critérios de Aceite

- [ ] **AC1:** Grid de KPIs exibe card "Média por Entrega" como 4º card da linha "Entregues" com o valor em R$
- [ ] **AC2:** Cálculo: `SUM(validated_hours × hourly_rate) / COUNT(tasks delivered)` — sem N+1 (SQL puro)
- [ ] **AC3:** Para múltiplas empresas, usar média ponderada (cada task com o `hourly_rate` da sua empresa)
- [ ] **AC4:** Exibe `R$ 0,00` quando não há cards entregues no mês (evitar divisão por zero)
- [ ] **AC5:** Ao lado do botão `+`, na margem direita da mesma linha, exibe "Média por Entrega: R$ XX,XX"
- [ ] **AC6:** Ambas as exibições respeitam os filtros ativos (empresa, projeto, período)
- [ ] **AC7:** Ambas as exibições atualizam via Turbo Stream quando status de task muda para/de `delivered`
- [ ] **AC8:** Specs cobrem o cálculo incluindo caso com zero entregas (sem divisão por zero)

---

## Análise Técnica

### Query — sem N+1

```ruby
# No DashboardController (ou DashboardCalculations concern)
delivered = tasks.delivered.joins(:company)
delivered_value = delivered.sum("tasks.validated_hours * companies.hourly_rate")
delivered_count = delivered.count
@monthly_avg_per_delivery = delivered_count > 0 ? delivered_value / delivered_count : 0
```

### Partials e IDs Turbo Stream

| Localização | Partial | ID Turbo Stream |
|-------------|---------|----------------|
| Grid KPIs (linha entregues) | `dashboard/_avg_per_delivery.html.erb` | `kpi-media-por-entrega` |
| Ao lado do botão + | `dashboard/_avg_per_delivery_inline.html.erb` | `kpi-media-por-entrega-inline` |

### Botão + — linha com média

A linha do botão + (`bg-blue-900 p-3`) já existe. Adicionar ao lado direito:

```erb
<div class="flex items-center justify-between bg-blue-900 p-3 rounded-lg">
  <%= link_to new_task_path, ... do %>
    <!-- ícone + -->
  <% end %>
  <turbo-frame id="kpi-media-por-entrega-inline">
    <%= render "dashboard/avg_per_delivery_inline", avg: @monthly_avg_per_delivery %>
  </turbo-frame>
</div>
```

### Turbo Stream — onde adicionar

- `TasksController#deliver` — adicionar `turbo_stream.replace` para `kpi-media-por-entrega` e `kpi-media-por-entrega-inline`
- `TaskItemsController#create`, `#update`, `#destroy` — idem

### Dependência de story 5.19

Esta story depende dos assigns `@monthly_delivered_count` e `@monthly_delivered_value` criados na story 5.19. Pode ser implementada em sequência ou em paralelo (adicionando os assigns necessários aqui também).

---

## Arquivos a Criar/Modificar

| Arquivo | Ação |
|---------|------|
| `app/controllers/dashboard_controller.rb` | Adicionar `@monthly_avg_per_delivery` |
| `app/controllers/concerns/dashboard_calculations.rb` | Adicionar método `calculate_avg_per_delivery` (se concern existir) |
| `app/views/dashboard/index.html.erb` | 4º card na linha Entregues + elemento ao lado do botão + |
| `app/views/dashboard/_avg_per_delivery.html.erb` | Criar partial do card KPI |
| `app/views/dashboard/_avg_per_delivery_inline.html.erb` | Criar partial inline ao lado do botão + |
| `app/controllers/tasks_controller.rb` | Adicionar `turbo_stream.replace` para os 2 novos IDs no `deliver` |
| `app/controllers/task_items_controller.rb` | Adicionar `turbo_stream.replace` para os 2 novos IDs em create/update/destroy |
| `spec/requests/dashboard_kpis_spec.rb` | Specs do KPI com zero entregas e com entregas |

---

## Testes

- [ ] `GET /` — assign `@monthly_avg_per_delivery` presente
- [ ] Renderiza `_avg_per_delivery` e `_avg_per_delivery_inline`
- [ ] Exibe `R$ 0,00` quando `delivered_count == 0` (sem divisão por zero)
- [ ] Exibe valor correto com tasks delivered de uma única empresa
- [ ] Exibe valor correto com tasks delivered de múltiplas empresas (média ponderada)
- [ ] Turbo Streams disparados no `deliver` e em `task_items#create/update/destroy`

---

## Dependências

- Story 5.19 — assigns de delivered (pode ser implementada em sequência)
- `Task.delivered` scope — **já existe**
- `Company#hourly_rate` — **já existe**
- `Task#validated_hours` — campo persistido — **já existe**
- Padrão de Turbo Streams nos controllers — **já estabelecido**

---

## Estimativa

**2 story points** (~3h) — 2 partials novos + assign no controller + Turbo Streams em 2 controllers + inline ao lado do botão +.
