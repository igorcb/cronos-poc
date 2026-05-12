# Story 5.13: Exibir Horas Realizadas ao Lado do Estimado no Dashboard

**Status:** done
**Domínio:** DM-005-visualizacao-totalizadores
**Data:** 2026-04-26
**Epic:** Epic 5 — Visualização & Dashboard
**Story ID:** 5.13
**Story Key:** 5-13-exibir-horas-realizadas-ao-lado-do-estimado

---

## Contexto

A coluna "Estimado" no dashboard exibe apenas as horas estimadas da task (`task.estimated_hours_hm`, ex: `4:00`). O usuário precisa ver também o total de horas efetivamente lançadas (realizadas) na mesma célula, para comparar progresso vs. estimativa sem precisar abrir a task.

O model `Task` já possui o método `total_hours` (soma de `task_items.hours_worked`).

---

## História do Usuário

**Como** usuário do Cronos POC,
**Quero** ver na coluna "Estimado" do dashboard tanto as horas estimadas quanto as horas realizadas,
**Para** comparar rapidamente o progresso real vs. estimativa de cada task sem abrir nenhuma tela.

---

## Critérios de Aceite

- [x] **AC1:** A célula da coluna "Estimado" exibe no formato `HH:MM / HH:MM` — estimado / realizado
  - Exemplo: `4:00 / 2:30` (estimado 4h, lançado 2h30)
- [x] **AC2:** As horas realizadas usam o método `task.total_hours` convertido para formato HH:MM
- [x] **AC3:** Quando não há task_items lançados, as horas realizadas exibem `0:00`
- [x] **AC4:** A coluna mantém o cabeçalho "Estimado" (ou pode ser renomeada para "Est / Real" — a critério do dev)
- [x] **AC5:** O eager loading existente (`includes(:task_items)`) já carrega os dados necessários — sem N+1

---

## Análise Técnica

### Method disponível no model Task

```ruby
def total_hours
  task_items.sum(:hours_worked)  # => retorna Decimal (ex: 2.5)
end
```

### Conversão para HH:MM

Usar o helper existente `decimal_to_hm` (já presente no model) ou criar um helper de view:

```ruby
# No model Task — já existe:
def decimal_to_hm(decimal)
  return "0:00" if decimal.nil? || decimal.zero?
  hours = decimal.to_i
  minutes = ((decimal - hours) * 60).round
  sprintf("%d:%02d", hours, minutes)
end
```

Para usar nas views, expor como método público ou usar helper:

```ruby
def total_hours_hm
  decimal_to_hm(total_hours)
end
```

### Partial `_task_row.html.erb`

```erb
<%# antes %>
<td class="px-4 py-3 text-sm text-gray-300"><%= task.estimated_hours_hm %></td>

<%# depois %>
<td class="px-4 py-3 text-sm text-gray-300">
  <span class="text-gray-300"><%= task.estimated_hours_hm %></span>
  <span class="text-gray-500 mx-1">/</span>
  <span class="<%= task.total_hours > 0 ? 'text-green-400' : 'text-gray-500' %>"><%= task.total_hours_hm %></span>
</td>
```

> **Decisão de cor:** horas realizadas em verde quando > 0, cinza quando 0.

---

## Arquivos a Modificar

| Arquivo | Ação |
|---------|------|
| `app/models/task.rb` | Adicionar método público `total_hours_hm` |
| `app/views/dashboard/_task_row.html.erb` | Atualizar célula "Estimado" para exibir `estimado / realizado` |

---

## Testes

- [x] `spec/models/task_spec.rb` — `total_hours_hm` retorna "00:00" sem task_items; retorna "02:30" com 2.5h lançadas; cobre múltiplos cenários
- [x] `spec/requests/dashboard_tasks_month_spec.rb` — verifica separador `/`, horas realizadas "02:30", estimado fixo "04:00", e AC3 com "00:00"

---

## Dependências

- `task.total_hours` — **já existe** no model
- `decimal_to_hm` — **já existe** no model (privado; tornar público ou duplicar como `total_hours_hm`)
- `includes(:task_items)` no `DashboardController#index` — **já presente**

---

## Estimativa

**1 story point** (~1,5h) — método simples no model + ajuste no partial.

---

## Dev Agent Record

### Implementation Plan

1. Adicionado método público `total_hours_hm` em `app/models/task.rb` delegando para `decimal_to_hm(total_hours)`
2. Atualizado partial `app/views/dashboard/_task_row.html.erb` — célula Estimado agora exibe `<estimado> / <realizado>` com cores diferenciadas (verde quando > 0, cinza quando 0)
3. Renomeado cabeçalho da coluna de "Estimado" para "Est / Real" em `app/views/dashboard/index.html.erb` (AC4)
4. Atualizado spec AC3 no `dashboard_tasks_month_spec.rb` para refletir novo cabeçalho "Est / Real"
5. Adicionados 4 novos specs em `spec/models/task_spec.rb` para `#total_hours_hm`
6. Adicionados 5 novos specs de request em `spec/requests/dashboard_tasks_month_spec.rb` para Story 5.13

### Completion Notes

- AC5 (N+1): `includes(:task_items)` já presente no `DashboardController#index` — confirmado sem regressões
- `decimal_to_hm` é método privado no model — `total_hours_hm` é wrapper público que o reutiliza
- Factory `:task_item` calcula `hours_worked` via callback (`before_save :calculate_hours_worked`) — testes usam `start_time`/`end_time` para controlar o valor
- **QA H1 — Corrigido:** segundo `private` duplicado na linha 163 removido do `task.rb`
- **QA H2 — Corrigido:** specs de `#total_hours`, `#total_hours_hm` e `#calculated_value` não passam mais `hours_worked:` diretamente — apenas `start_time`/`end_time`
- **QA M1 — Corrigido:** adicionado spec verificando `text-green-400` para horas > 0
- **QA M2 — Corrigido:** guarda de `decimal_to_hm` alterada para `decimal.nil? || decimal.to_f <= 0`
- **QA L2 — Corrigido:** spec AC3 agora verifica `class="text-gray-500">00:00</span>` ao invés de string genérica
- 770 specs: 20 falhas são todas pré-existentes no master — zero novas regressões

### File List

- `app/models/task.rb` — adicionado `total_hours_hm`
- `app/views/dashboard/_task_row.html.erb` — célula estimado atualizada com formato Est / Real
- `app/views/dashboard/index.html.erb` — cabeçalho renomeado para "Est / Real"
- `spec/models/task_spec.rb` — adicionado `describe "#total_hours_hm"` com 4 specs
- `spec/requests/dashboard_tasks_month_spec.rb` — atualizado AC3 + adicionados 5 specs Story 5.13

### Change Log

- 2026-05-04: Implementação Story 5.13 — `total_hours_hm` no model, partial `_task_row` atualizado, 9 novos specs, 769 testes passando
- 2026-05-04: Ajustes QA — H1 duplo private, H2 specs frágeis, M1 spec cor verde, M2 guarda decimal_to_hm, L2 spec AC3 específico. 770 examples, 20 falhas pré-existentes no master
