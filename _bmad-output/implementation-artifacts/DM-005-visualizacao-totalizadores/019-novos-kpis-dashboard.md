# Story 5.19: Novos KPIs do Dashboard — Entregas do Mês, Horas Entregues, Valor Entregue

**Status:** ready-for-dev
**Domínio:** DM-005-visualizacao-totalizadores
**Data:** 2026-05-06
**Epic:** Epic 5 — Visualização & Dashboard
**Story ID:** 5.19
**Story Key:** 5-19-novos-kpis-dashboard

---

## Contexto

O dashboard exibe 6 KPIs globais (Tarefas Mês, Tarefas Hoje, Horas Mês, Horas Hoje, Valor Mês, Valor Hoje), mas nenhum deles distingue tasks entregues (`delivered`) de tasks em aberto. O usuário precisa visualizar rapidamente o que já foi faturável no mês — separado do total geral.

Esta story adiciona uma terceira linha de KPIs focada exclusivamente nas tasks `delivered` do mês atual, formando um grid 3×3 completo.

---

## História do Usuário

**Como** Igor,
**Quero** ver no dashboard quantas tarefas entreguei no mês com suas horas e valor correspondentes,
**Para** saber imediatamente o que já foi faturável sem precisar filtrar manualmente.

---

## Layout Proposto

```
┌─────────────────┬──────────────────┬─────────────────┐
│ Entregas do Mês │ Horas Entregues  │ Valor Entregue  │  ← NOVO (linha topo)
├─────────────────┼──────────────────┼─────────────────┤
│ Tarefas do Mês  │  Horas do Mês    │  Valor do Mês   │  ← Existente
├─────────────────┼──────────────────┼─────────────────┤
│ Tarefas Hoje    │   Horas Hoje     │   Valor Hoje    │  ← Existente
└─────────────────┴──────────────────┴─────────────────┘
```

---

## Critérios de Aceite

- [ ] **AC1:** Dashboard exibe linha "Entregues" acima da linha "Mês" com 3 cards: Entregas do Mês, Horas Entregues, Valor Entregue
- [ ] **AC2:** "Entregas do Mês" exibe contagem de tasks com `status = delivered` no mês atual
- [ ] **AC3:** "Horas Entregues" exibe soma de `validated_hours` das tasks `delivered` do mês (formato HH:MM)
- [ ] **AC4:** "Valor Entregue" exibe valor monetário das tasks `delivered` do mês (formato R$ X.XXX,XX)
- [ ] **AC5:** Os 3 novos KPIs respeitam os filtros ativos (empresa, projeto, período) — mesma base de query dos demais totalizadores
- [ ] **AC6:** Os 3 novos KPIs atualizam via Turbo Stream quando uma task muda para/de `delivered` (no `TasksController#deliver` e `TaskItemsController#create/update/destroy`)
- [ ] **AC7:** Layout responsivo — em mobile os 9 cards empilham corretamente (3 linhas × 3 colunas → 1 coluna no mobile)
- [ ] **AC8:** Specs cobrem os 3 novos KPIs (assigns do controller + renderização dos partials)

---

## Análise Técnica

### Queries — evitar N+1

Calcular via SQL direto no `DashboardController`:

```ruby
# tasks delivered no mês — mesma base filtrada
delivered_tasks = tasks.delivered

@monthly_delivered_count = delivered_tasks.count
@monthly_delivered_hours = delivered_tasks.sum(:validated_hours)
@monthly_delivered_value = delivered_tasks.joins(:company)
                                          .sum("tasks.validated_hours * companies.hourly_rate")
```

> Usar `validated_hours` (campo persistido) em vez de recalcular via `task_items` — sem N+1.

### Partials sugeridos

| Partial | ID Turbo Stream |
|---------|----------------|
| `dashboard/_delivered_count.html.erb` | `kpi-entregas-mes` |
| `dashboard/_delivered_hours.html.erb` | `kpi-horas-entregues` |
| `dashboard/_delivered_value.html.erb` | `kpi-valor-entregue` |

### Turbo Stream — onde adicionar

- `TasksController#deliver` — já atualiza streams; adicionar os 3 novos IDs
- `TaskItemsController#create`, `#update`, `#destroy` — já enviam streams de KPIs; adicionar os 3 novos

### Referência de padrão

Ver story 5.10 (`010-expandir-kpis-dashboard-6-metricas.md`) — adicionou os 6 KPIs existentes. Seguir o mesmo padrão de partials e Turbo Streams.

---

## Arquivos a Criar/Modificar

| Arquivo | Ação |
|---------|------|
| `app/controllers/dashboard_controller.rb` | Adicionar `@monthly_delivered_count`, `@monthly_delivered_hours`, `@monthly_delivered_value` |
| `app/controllers/concerns/dashboard_calculations.rb` | Adicionar métodos de cálculo de delivered (se concern existir) |
| `app/views/dashboard/index.html.erb` | Adicionar linha de KPIs "Entregues" acima da linha "Mês" |
| `app/views/dashboard/_delivered_count.html.erb` | Criar partial do card Entregas do Mês |
| `app/views/dashboard/_delivered_hours.html.erb` | Criar partial do card Horas Entregues |
| `app/views/dashboard/_delivered_value.html.erb` | Criar partial do card Valor Entregue |
| `app/controllers/tasks_controller.rb` | Adicionar `turbo_stream.replace` para os 3 novos cards no action `deliver` |
| `app/controllers/task_items_controller.rb` | Adicionar `turbo_stream.replace` para os 3 novos cards em create/update/destroy |
| `spec/requests/dashboard_kpis_spec.rb` | Specs dos 3 novos KPIs |

---

## Testes

- [ ] `GET /` — assigns `@monthly_delivered_count`, `@monthly_delivered_hours`, `@monthly_delivered_value` presentes
- [ ] Renderiza partials `_delivered_count`, `_delivered_hours`, `_delivered_value`
- [ ] KPIs exibem `0` / `R$ 0,00` / `0:00` quando não há tasks delivered no mês
- [ ] KPIs exibem valores corretos com tasks delivered
- [ ] Turbo Streams disparados no `deliver` e no `task_items#create/update/destroy`

---

## Dependências

- `Task.delivered` scope — **já existe** (`enum :status`)
- `Task#validated_hours` — campo persistido, atualizado via `after_save` callback
- `DashboardController` com base de tasks filtrada — **já existe**
- Padrão de Turbo Streams nos controllers — **já estabelecido** em stories 5.10, 5.11, 5.18

---

## Estimativa

**2 story points** (~4h) — 3 partials novos + assigns no controller + Turbo Streams em 2 controllers.
