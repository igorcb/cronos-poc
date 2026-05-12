# Story 5.10: Expandir KPIs do Dashboard — 6 Métricas Globais

**Status:** done
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

- [x] O grid de KPIs passa de 3 para 6 cards, mantendo layout responsivo (`grid-cols-1 md:grid-cols-2 lg:grid-cols-3`)
- [x] **KPI 4 — Qtde Tasks Mês:** total de tasks do mês corrente (global, sem filtro)
- [x] **KPI 5 — Qtde Tasks Hoje:** total de tasks com task_items com `work_date = today`
- [x] **KPI 6 — Valor Hoje:** soma de `hours_worked × company.hourly_rate` dos task_items do dia corrente (global)
- [x] Os 3 novos KPIs **não são afetados** pelos filtros de empresa/projeto/status/período da listagem
- [x] Os 3 KPIs existentes (Horas Hoje, Horas Mês, Valor Mês) permanecem inalterados
- [x] Todos os 6 KPIs são calculados no `DashboardController#index`
- [x] Layout consistente com os cards existentes (mesmo estilo visual)

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

- [x] `spec/requests/dashboard_kpis_spec.rb` — 25 exemplos cobrindo os 3 novos assigns
- [x] Testar com `work_date = Date.current` para garantir contagem de hoje
- [x] Testar com task_items de dias anteriores para garantir que não aparecem em "hoje"

---

## Dependências

- Story 5.9 (campo `work_date` em task_items) — **já implementada**
- `companies.hourly_rate` — já disponível no model Company

---

## Estimativa

**2 story points** (~3h) — queries simples, 3 partials novos, sem migração.

---

## Dev Agent Record

### Implementation Plan

1. **Controller** — Adicionei 3 métodos privados: `calculate_daily_task_count`, `calculate_monthly_task_count`, `calculate_daily_value`. Todos usam `work_date` (não `start_date`) pois KPIs de task_items devem refletir o dia de trabalho registrado.
2. **Partials** — 3 novos partials com mesmo padrão visual dos existentes: ícone colorido + label + valor.
3. **View** — Grid alterado de `md:grid-cols-3` para `md:grid-cols-2 lg:grid-cols-3`, adicionados os 3 novos renders.

### Decisões técnicas

- **`work_date` vs `start_date`**: KPIs de task_items usam `work_date` (data real do trabalho). Os KPIs existentes (horas e valor mensal) usam `start_date` da task — mantidos sem alteração.
- **`distinct.count`**: tasks podem ter múltiplos task_items no mesmo dia; distinct evita dupla contagem.
- Cores escolhidas: purple (tasks hoje), indigo (tasks mês), orange (valor hoje) — distintas das existentes (blue, green, yellow).

### Completion Notes

- 25 testes criados em `spec/requests/dashboard_kpis_spec.rb`, todos passando.
- Suite completa: 731 exemplos, 4 falhas pré-existentes (não relacionadas), zero regressões.
- Todos os 8 ACs satisfeitos.

### File List

- `app/controllers/dashboard_controller.rb` (modificado)
- `app/views/dashboard/index.html.erb` (modificado)
- `app/views/dashboard/_daily_task_count.html.erb` (criado)
- `app/views/dashboard/_monthly_task_count.html.erb` (criado)
- `app/views/dashboard/_daily_value.html.erb` (criado)
- `spec/requests/dashboard_kpis_spec.rb` (criado)

### Change Log

- 2026-04-24: Implementação da story 5.10 — 3 novos KPIs no dashboard (Tasks Hoje, Tasks Mês, Valor Hoje). Controller expandido com 3 métodos privados. 3 partials criados. Grid atualizado para 6 cards responsivos. 25 testes adicionados.
