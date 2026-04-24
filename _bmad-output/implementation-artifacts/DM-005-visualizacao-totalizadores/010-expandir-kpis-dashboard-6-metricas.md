# Story 5.10: Expandir KPIs do Dashboard — 6 Métricas Globais

**Status:** ready-for-dev
**Domínio:** DM-005-visualizacao-totalizadores
**Data:** 2026-04-24
**Epic:** Epic 5 — Visualização & Dashboard
**Story ID:** 5.10
**Story Key:** 5-10-expandir-kpis-dashboard-6-metricas

---

## Contexto

O dashboard atual exibe 3 KPIs no topo: **Horas Hoje**, **Horas Mês** e **Valor Mês**.

O usuário precisa de visibilidade adicional sobre **quantidade de tasks** (total no mês e lançadas hoje) e o **valor monetário do dia**, sem precisar acessar a listagem de tasks ou aplicar filtros.

Esses KPIs devem ser **globais** — calculados sobre todos os dados do usuário, independente dos filtros ativos na listagem.

---

## História do Usuário

**Como** usuário do Cronos POC,
**Quero** ver 6 KPIs no topo do dashboard (3 existentes + 3 novos),
**Para** ter visão imediata do meu volume de trabalho (quantidade de tasks e valor financeiro) sem precisar navegar para outra tela.

---

## Critérios de Aceite

- [ ] O grid de KPIs passa de 3 para 6 cards, mantendo layout responsivo (`grid-cols-1 md:grid-cols-3 lg:grid-cols-6` ou `md:grid-cols-2 lg:grid-cols-3` em dois blocos)
- [ ] **KPI 4 — Qtde Tasks Mês:** total de tasks do mês corrente (global, sem filtro)
- [ ] **KPI 5 — Qtde Tasks Hoje:** total de tasks lançadas hoje (com `work_date = today` em task_items, ou tasks com `created_at` hoje — definir com dev)
- [ ] **KPI 6 — Valor Hoje:** soma de `hours_worked × company.hourly_rate` dos task_items do dia corrente (global)
- [ ] Os 3 novos KPIs **não são afetados** pelos filtros de empresa/projeto/status/período da listagem
- [ ] Os 3 KPIs existentes (Horas Hoje, Horas Mês, Valor Mês) permanecem inalterados
- [ ] Todos os 6 KPIs são calculados no `DashboardController#index`
- [ ] Layout consistente com os cards existentes (mesmo estilo visual)

---

## Análise Técnica

### KPIs existentes (no DashboardController)

```ruby
@daily_hours   # => partial: dashboard/daily_hours
@monthly_hours # => partial: dashboard/monthly_hours
@monthly_value # => partial: dashboard/monthly_value
```

### Novos assigns a adicionar

```ruby
# Qtde de tasks do mês (Tasks com pelo menos 1 task_item no mês corrente,
# ou Tasks criadas no mês — confirmar com dev qual a base correta)
@monthly_task_count = Task.joins(:task_items)
                          .where(task_items: { work_date: Date.current.all_month })
                          .distinct.count

# Qtde de tasks hoje
@daily_task_count = Task.joins(:task_items)
                        .where(task_items: { work_date: Date.current })
                        .distinct.count

# Valor monetário do dia
@daily_value = TaskItem.joins(task: :company)
                       .where(work_date: Date.current)
                       .sum("task_items.hours_worked * companies.hourly_rate")
```

> **Nota:** Usar `work_date` (campo adicionado na story 5.9) como base para "hoje" e "mês".

### Partials a criar

- `app/views/dashboard/_monthly_task_count.html.erb`
- `app/views/dashboard/_daily_task_count.html.erb`
- `app/views/dashboard/_daily_value.html.erb`

### View — dashboard/index.html.erb

```erb
<!-- Quick Stats — grid de 6 KPIs -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  <%= render "dashboard/daily_hours",       daily_hours: @daily_hours %>
  <%= render "dashboard/monthly_hours",     monthly_hours: @monthly_hours %>
  <%= render "dashboard/monthly_value",     monthly_value: @monthly_value %>
  <%= render "dashboard/daily_task_count",  daily_task_count: @daily_task_count %>
  <%= render "dashboard/monthly_task_count", monthly_task_count: @monthly_task_count %>
  <%= render "dashboard/daily_value",       daily_value: @daily_value %>
</div>
```

---

## Arquivos a Modificar

| Arquivo | Ação |
|---------|------|
| `app/controllers/dashboard_controller.rb` | Adicionar `@monthly_task_count`, `@daily_task_count`, `@daily_value` |
| `app/views/dashboard/index.html.erb` | Expandir grid de 3 para 6 cards |
| `app/views/dashboard/_monthly_task_count.html.erb` | Criar |
| `app/views/dashboard/_daily_task_count.html.erb` | Criar |
| `app/views/dashboard/_daily_value.html.erb` | Criar |

---

## Testes

- [ ] `spec/requests/dashboard_spec.rb` — verificar que os 3 novos assigns estão presentes
- [ ] Testar com `work_date = Date.current` para garantir contagem de hoje
- [ ] Testar com task_items de dias anteriores para garantir que não aparecem em "hoje"

---

## Dependências

- Story 5.9 (campo `work_date` em task_items) — **já implementada**
- `companies.hourly_rate` — já disponível no model Company

---

## Estimativa

**2 story points** (~3h) — queries simples, 3 partials novos, sem migração.
