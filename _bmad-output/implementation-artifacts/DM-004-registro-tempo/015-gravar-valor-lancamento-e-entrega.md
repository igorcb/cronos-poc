# Story 4.15: Gravar Valor Monetário no Lançamento e na Entrega da Task

**Status:** ready-for-dev
**Domínio:** DM-004-registro-tempo
**Data:** 2026-05-07
**Epic:** Epic 4 — Task Management
**Story ID:** 4.15
**Story Key:** 4-15-gravar-valor-lancamento-e-entrega

---

## Contexto

Atualmente o valor monetário de uma task é calculado dinamicamente (`validated_hours × company.hourly_rate`). Se a tarifa da empresa mudar, os valores históricos mudam junto — perdendo a rastreabilidade financeira.

Esta story adiciona persistência de valor em dois momentos:
1. **No lançamento de horas** — cada `task_item` grava `hourly_rate` e `value` no momento do lançamento
2. **Na entrega da task** — a task grava `hourly_rate` e `delivered_value` no momento da entrega

A coluna de valor na listagem/dashboard passa a exibir a **soma real dos lançamentos** (`SUM(task_items.value)`), não mais o valor calculado dinamicamente.

---

## História do Usuário

**Como** Igor,
**Quero** que o valor de cada lançamento de horas seja calculado e gravado no momento do lançamento com a tarifa vigente,
**Para** ter histórico financeiro imutável independente de mudanças futuras na tarifa da empresa.

---

## Critérios de Aceite

- [ ] **AC1 — Migration TaskItem:** Adicionar colunas `hourly_rate` (decimal 10,2) e `value` (decimal 10,2) na tabela `task_items`
- [ ] **AC2 — Migration Task:** Adicionar colunas `hourly_rate` (decimal 10,2) e `delivered_value` (decimal 10,2) na tabela `tasks`
- [ ] **AC3 — Lançamento grava tarifa e valor:** No `before_save` do `TaskItem`, calcular e gravar `hourly_rate = task.company.hourly_rate` e `value = hours_worked × hourly_rate`
- [ ] **AC4 — Entrega grava tarifa e valor:** No `before_save` do `Task` (callback `update_delivery_date`), gravar `hourly_rate = company.hourly_rate` e `delivered_value = task_items.sum(:value)`
- [ ] **AC5 — Coluna valor no dashboard:** `_task_row.html.erb` exibe `task_items.sum(:value)` formatado em R$ (com eager loading — sem N+1)
- [ ] **AC6 — Coluna valor na listagem:** `TaskCardComponent` exibe `task_items.sum(:value)` em vez de `calculated_value`
- [ ] **AC7 — Retrocompatibilidade:** Tasks e task_items existentes sem valor gravado exibem `R$ 0,00` (colunas nullable)
- [ ] **AC8 — Specs:** Migration, callbacks e exibição cobertos por testes

---

## Análise Técnica

### Migrations

```ruby
# Migration 1: task_items
add_column :task_items, :hourly_rate, :decimal, precision: 10, scale: 2
add_column :task_items, :value, :decimal, precision: 10, scale: 2

# Migration 2: tasks
add_column :tasks, :hourly_rate, :decimal, precision: 10, scale: 2
add_column :tasks, :delivered_value, :decimal, precision: 10, scale: 2
```

### TaskItem — callback `before_save`

Estender o `before_save :calculate_hours_worked` existente ou adicionar callback separado:

```ruby
before_save :calculate_value

def calculate_value
  rate = task.company&.hourly_rate || 0
  self.hourly_rate = rate
  self.value = (hours_worked || 0) * rate
end
```

### Task — callback na entrega

No `update_delivery_date` (já existe, disparado por `before_save` quando `status_changed_to_delivered?`):

```ruby
def update_delivery_date
  self.delivery_date = Date.today
  self.hourly_rate = company&.hourly_rate
  self.delivered_value = task_items.sum(:value)
end
```

### Exibição do valor acumulado

```ruby
# Task — método helper
def total_value
  task_items.sum(:value)
end
```

Nas views, substituir `task.calculated_value` por `task.total_value`.

### Eager loading

O `DashboardController` já faz `includes(:task_items)`. Com `task_items` carregados, `task_items.sum(:value)` é calculado em Ruby (sem query extra). Verificar que `includes(:task_items)` também está no `TasksController#index`.

---

## Arquivos a Criar/Modificar

| Arquivo | Ação |
|---------|------|
| `db/migrate/TIMESTAMP_add_value_to_task_items.rb` | Criar migration — `hourly_rate` e `value` em `task_items` |
| `db/migrate/TIMESTAMP_add_value_to_tasks.rb` | Criar migration — `hourly_rate` e `delivered_value` em `tasks` |
| `app/models/task_item.rb` | Adicionar `before_save :calculate_value` |
| `app/models/task.rb` | Atualizar `update_delivery_date`; adicionar `total_value` |
| `app/views/dashboard/_task_row.html.erb` | Usar `task.total_value` no lugar de `calculated_value` |
| `app/components/task_card_component.rb` | Usar `task.total_value` no lugar de `calculated_value` |
| `app/components/task_card_component.html.erb` | Verificar exibição |
| `spec/models/task_item_spec.rb` | Specs do callback `calculate_value` |
| `spec/models/task_spec.rb` | Specs do `total_value` e `update_delivery_date` com valor |

---

## Dependências

- `task.company.hourly_rate` — **já existe** no model Company
- `before_save :calculate_hours_worked` — **já existe** no TaskItem; `calculate_value` deve rodar após (ou ser parte do mesmo callback)
- `before_save :update_delivery_date` — **já existe** no Task
- `includes(:task_items)` no DashboardController — **já existe**

---

## Observações

- Colunas são **nullable** — registros existentes ficam com `nil`, exibidos como `R$ 0,00`
- `delivered_value` na task é um **snapshot imutável** do momento da entrega — não recalcula se task_items mudarem depois
- `hourly_rate` no task_item permite auditoria futura: saber qual tarifa estava vigente em cada lançamento

---

## Estimativa

**3 story points** (~5h) — 2 migrations + 2 callbacks + atualização de views/components + specs.
