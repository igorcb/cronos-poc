# Story 5.13: Exibir Horas Realizadas ao Lado do Estimado no Dashboard

**Status:** ready-for-dev
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

- [ ] **AC1:** A célula da coluna "Estimado" exibe no formato `HH:MM / HH:MM` — estimado / realizado
  - Exemplo: `4:00 / 2:30` (estimado 4h, lançado 2h30)
- [ ] **AC2:** As horas realizadas usam o método `task.total_hours` convertido para formato HH:MM
- [ ] **AC3:** Quando não há task_items lançados, as horas realizadas exibem `0:00`
- [ ] **AC4:** A coluna mantém o cabeçalho "Estimado" (ou pode ser renomeada para "Est / Real" — a critério do dev)
- [ ] **AC5:** O eager loading existente (`includes(:task_items)`) já carrega os dados necessários — sem N+1

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

- [ ] `spec/models/task_spec.rb` — `total_hours_hm` retorna "0:00" sem task_items; retorna "2:30" com 2.5h lançadas
- [ ] `spec/requests/dashboard_spec.rb` (ou arquivo existente) — verificar que a célula exibe o separador `/` e as horas realizadas

---

## Dependências

- `task.total_hours` — **já existe** no model
- `decimal_to_hm` — **já existe** no model (privado; tornar público ou duplicar como `total_hours_hm`)
- `includes(:task_items)` no `DashboardController#index` — **já presente**

---

## Estimativa

**1 story point** (~1,5h) — método simples no model + ajuste no partial.
