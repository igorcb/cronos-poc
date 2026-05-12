# Story 5.16: Ajustes Visuais — Cores de Badge, Ordem dos KPIs e Botão Lançar Horas

**Status:** done
**Domínio:** DM-005-visualizacao-totalizadores
**Data:** 2026-04-30
**Epic:** Epic 5 — Visualização & Dashboard
**Story ID:** 5.16
**Story Key:** 5-16-ajustes-visuais-dashboard-badges-kpis-botoes

---

## Contexto

Após a implementação das stories anteriores, o usuário identificou três melhorias visuais necessárias no dashboard: as cores dos badges de status precisavam ser trocadas (completed=azul, delivered=verde), o botão de lançar horas devia ser desabilitado quando a task estiver entregue, e a ordem dos KPIs devia ser reorganizada para melhor leitura.

---

## História do Usuário

**Como** usuário do Cronos POC,
**Quero** que o dashboard tenha as cores corretas nos badges, os KPIs organizados de forma intuitiva e os botões de ação respeitando o estado da task,
**Para** ter uma experiência visual consistente e não cometer erros de operação.

---

## Critérios de Aceite

- [x] **AC1 — Badge completed = azul:** status `completed` exibe badge azul (`bg-blue-900 text-blue-300 border-blue-700`)
- [x] **AC2 — Badge delivered = verde:** status `delivered` exibe badge verde (`bg-green-900 text-green-300 border-green-700`)
- [x] **AC3 — Botão lançar horas desabilitado em delivered:** quando `task.delivered?`, o botão relógio é substituído por span cinza `cursor-not-allowed` com `aria-disabled="true"`
- [x] **AC4 — Ordem dos KPIs:** linha 1 = Tasks Mês | Horas Mês | Valor Mês; linha 2 = Tasks Hoje | Horas Hoje | Valor Hoje
- [x] **AC5 — Consistência tasks/_task_row e components/task_card:** ambas as views aplicam as mesmas regras de badge e botão desabilitado

---

## Análise Técnica

### Cores de Badge — `StatusBadgeComponent`

```ruby
# app/components/status_badge_component.rb
when "completed" then "bg-blue-900 text-blue-300 border border-blue-700"
when "delivered" then "bg-green-900 text-green-300 border border-green-700"
```

### Botão desabilitado em `_task_row.html.erb`

```erb
<% if task.delivered? %>
  <span role="button"
        class="inline-flex items-center justify-center w-8 h-8 bg-gray-700 text-gray-500 rounded cursor-not-allowed"
        aria-label="Lançar horas indisponível — tarefa entregue"
        aria-disabled="true">
    <!-- ícone relógio -->
  </span>
<% else %>
  <%= link_to new_task_task_item_path(task), data: { turbo_frame: "modal" }, ... %>
<% end %>
```

### Ordem dos KPIs — `dashboard/index.html.erb`

```erb
<%= render "dashboard/monthly_task_count", ... %>
<%= render "dashboard/monthly_hours",      ... %>
<%= render "dashboard/monthly_value",      ... %>
<%= render "dashboard/daily_task_count",   ... %>
<%= render "dashboard/daily_hours",        ... %>
<%= render "dashboard/daily_value",        ... %>
```

---

## Arquivos Modificados

| Arquivo | Ação |
|---------|------|
| `app/components/status_badge_component.rb` | Swap de cores completed/delivered |
| `app/views/dashboard/_task_row.html.erb` | Botão desabilitado em delivered + check de delivered no lançar horas |
| `app/components/task_card_component.html.erb` | Mesma lógica de botão desabilitado |
| `app/views/dashboard/index.html.erb` | Reordenação das partials de KPI |

---

## Estimativa

**0.5 story point** (~1h) — ajustes visuais sem lógica de negócio nova.

---

## Dev Agent Record

### Completion Notes

- ✅ AC1/AC2: Cores trocadas no `StatusBadgeComponent` — afeta dashboard, tasks list e modal
- ✅ AC3: `task.delivered?` desabilita o botão relógio em `_task_row` e `task_card_component`
- ✅ AC4: Grid do dashboard reordenado — Tasks Mês | Horas Mês | Valor Mês na linha 1
- ✅ AC5: Ambas as views (dashboard e tasks list) aplicam as mesmas regras

### Change Log

- 2026-04-30: Cores de badge trocadas, botão lançar horas desabilitado em delivered, KPIs reordenados
