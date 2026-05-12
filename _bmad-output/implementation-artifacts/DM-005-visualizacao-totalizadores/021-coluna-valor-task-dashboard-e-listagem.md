# Story 5.21: Exibir Valor da Task no Dashboard e na Listagem de Tasks

**Status:** done
**Domínio:** DM-005-visualizacao-totalizadores
**Data:** 2026-05-07
**Epic:** Epic 5 — Visualização & Dashboard
**Story ID:** 5.21
**Story Key:** 5-21-coluna-valor-task-dashboard-e-listagem

---

## Contexto

A coluna de horas Est/Real já existe no dashboard e na listagem de tasks. O usuário precisa ver o valor monetário de cada task na mesma linha.

A lógica de exibição do valor segue o estado da task (implementada em conjunto com story 4.15):

- **Task não entregue** → valor acumulado em tempo real: `SUM(task_items.value)`
- **Task entregue** → snapshot imutável gravado na entrega: `task.delivered_value`

Dessa forma o valor exibido é sempre consistente: em aberto mostra o acumulado real dos lançamentos; entregue mostra o valor congelado no momento da entrega.

---

## Dependência

Esta story **depende da story 4.15** (gravar `task_items.value` e `task.delivered_value`). Deve ser implementada após ou junto com a 4.15.

---

## História do Usuário

**Como** Igor,
**Quero** ver o valor monetário (R$) de cada task ao lado das horas Est/Real no dashboard e na listagem,
**Para** saber imediatamente quanto cada task vale sem calcular manualmente, com valor congelado após a entrega.

---

## Critérios de Aceite

- [x] **AC1:** No dashboard (`_task_row.html.erb`), nova coluna "Valor" exibe o valor da task à direita da coluna Est/Real
- [x] **AC2:** Task **não entregue** → exibe `SUM(task_items.value)` via método `task.total_value`
- [x] **AC3:** Task **entregue** → exibe `task.delivered_value` (snapshot gravado na entrega — não recalcula)
- [x] **AC4:** Na listagem de tasks (`TaskCardComponent`), aplicar a mesma lógica — substituir `calculated_value` por `task.display_value`
- [x] **AC5:** Quando valor é zero ou nil, exibe `R$ 0,00`
- [x] **AC6:** Cabeçalho da tabela do dashboard recebe coluna "Valor"
- [x] **AC7:** Sem N+1 — `task_items` já carregado via `includes` nos controllers

---

## Análise Técnica

### Método `display_value` no model Task

Encapsular a lógica de qual valor exibir:

```ruby
# app/models/task.rb
def display_value
  delivered? ? (delivered_value || 0) : total_value
end

def total_value
  task_items.sum(:value)
end
```

> `total_value` soma `task_items.value` (campo gravado na story 4.15). Com `includes(:task_items)` no controller, o cálculo é feito em Ruby sem query extra.

### Formatação nas views

```erb
<%= number_to_currency(task.display_value, unit: "R$", separator: ",", delimiter: ".") %>
```

### Dashboard — `_task_row.html.erb`

Adicionar `<td>` entre a coluna Est/Real e a coluna de ações:

```erb
<td class="px-4 py-3 text-sm text-gray-300">
  <%= number_to_currency(task.display_value, unit: "R$", separator: ",", delimiter: ".") %>
</td>
```

### Dashboard — cabeçalho

Em `app/views/dashboard/index.html.erb`, adicionar `<th>Valor</th>` alinhado com a nova coluna.

---

## Arquivos a Modificar

| Arquivo | Ação |
|---------|------|
| `app/models/task.rb` | Adicionar `display_value` e `total_value` |
| `app/views/dashboard/_task_row.html.erb` | Adicionar `<td>` com `display_value` |
| `app/views/dashboard/index.html.erb` | Adicionar `<th>Valor</th>` no cabeçalho |
| `app/components/task_card_component.rb` | Usar `task.display_value` |
| `app/components/task_card_component.html.erb` | Verificar exibição |
| `spec/models/task_spec.rb` | Specs de `display_value` — entregue vs não entregue |
| `spec/requests/dashboard_tasks_month_spec.rb` | Spec da coluna Valor no dashboard |

---

## Testes

- [x] `task.display_value` retorna `total_value` quando não entregue
- [x] `task.display_value` retorna `delivered_value` quando entregue (mesmo se task_items mudarem depois)
- [x] Dashboard renderiza coluna Valor com `R$0,00` para task sem lançamentos
- [x] Dashboard renderiza valor correto com lançamentos
- [x] Sem regressão nos specs existentes

---

## Estimativa

**1 story point** (~2h) — método no model + célula no partial + cabeçalho + specs.

---

## File List

- `db/migrate/20260507200211_add_value_to_task_items.rb` — nova migration: hourly_rate + value em task_items
- `db/migrate/20260507200222_add_delivered_value_to_tasks.rb` — nova migration: hourly_rate + delivered_value em tasks
- `db/schema.rb` — atualizado pelas migrations
- `app/models/task_item.rb` — callback `calculate_value` adicionado
- `app/models/task.rb` — métodos `total_value`, `display_value`; `update_delivery_date` snapshots hourly_rate e delivered_value
- `app/views/dashboard/_task_row.html.erb` — nova `<td>` com `display_value`
- `app/views/dashboard/index.html.erb` — novo `<th>Valor</th>` no cabeçalho
- `app/components/task_card_component.html.erb` — usa `task.display_value` no lugar de `calculated_value`
- `spec/models/task_spec.rb` — specs de `total_value`, `display_value`, `update_delivery_date` com snapshot
- `spec/models/task_item_spec.rb` — specs do callback `calculate_value`
- `spec/requests/dashboard_tasks_month_spec.rb` — specs AC1, AC2, AC3, AC5, AC6 coluna Valor

---

## Dev Agent Record

### Implementation Plan

Implementada como extensão da story 4.15 (pré-requisito não implementado). A branch inclui:

1. **Migrations**: `hourly_rate` + `value` em `task_items`; `hourly_rate` + `delivered_value` em `tasks`
2. **Callbacks**: `TaskItem#calculate_value` — grava tarifa e valor no momento do lançamento; `Task#update_delivery_date` — snapshots tarifa e valor total no momento da entrega
3. **Model methods**: `Task#total_value` (sum de task_items.value); `Task#display_value` (delivered? → delivered_value : total_value)
4. **Views**: `_task_row.html.erb` ganhou `<td>` com `display_value`; `index.html.erb` ganhou `<th>Valor</th>`; `task_card_component.html.erb` usa `display_value`
5. **N+1**: sem nova query — `includes(:task_items)` já existia no DashboardController concern e TasksController

### Completion Notes

- 829 specs, 0 failures — sem regressões
- `number_to_currency` gera `R$0,00` (sem espaço após R$) — specs ajustados para string exata
- Task com `delivered?` bloqueia criação de task_items — spec de snapshot usa `TaskItem.insert` para bypass

### Change Log

- 2026-05-07: Implementada story 5.21 + pré-requisito 4.15 — migrations, callbacks, display_value, views e specs
