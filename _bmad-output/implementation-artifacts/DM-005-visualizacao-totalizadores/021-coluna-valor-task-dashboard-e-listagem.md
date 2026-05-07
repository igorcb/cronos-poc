# Story 5.21: Exibir Valor da Task no Dashboard e na Listagem de Tasks

**Status:** ready-for-dev
**Domínio:** DM-005-visualizacao-totalizadores
**Data:** 2026-05-07
**Epic:** Epic 5 — Visualização & Dashboard
**Story ID:** 5.21
**Story Key:** 5-21-coluna-valor-task-dashboard-e-listagem

---

## Contexto

A coluna de horas Est/Real já existe no dashboard e na listagem de tasks. O usuário precisa ver o valor monetário de cada task (horas realizadas × tarifa da empresa) na mesma linha, sem precisar abrir a task ou consultar os totalizadores.

O método `task.calculated_value` já existe no model e é usado na listagem `/tasks` via `TaskCardComponent`. O dashboard (`_task_row.html.erb`) não exibe esse valor — esta story adiciona a coluna.

---

## História do Usuário

**Como** Igor,
**Quero** ver o valor monetário (R$) de cada task ao lado das horas Est/Real no dashboard e na listagem de tasks,
**Para** saber imediatamente quanto cada task vale sem precisar calcular manualmente.

---

## Critérios de Aceite

- [ ] **AC1:** No dashboard (`_task_row.html.erb`), nova coluna "Valor" exibe `task.calculated_value` formatado em R$ à direita da coluna Est/Real
- [ ] **AC2:** Na listagem de tasks (`TaskCardComponent`), a coluna "Valor" já existe — verificar que usa `calculated_value` e está consistente com o formato do dashboard
- [ ] **AC3:** Quando `calculated_value` é zero ou nil, exibe `R$ 0,00` (não dash ou vazio)
- [ ] **AC4:** O valor usa o método `calculated_value` existente no model (`validated_hours × company.hourly_rate`) — sem N+1 (company já carregado via eager loading)
- [ ] **AC5:** O cabeçalho da tabela do dashboard recebe coluna "Valor" alinhada com a nova célula
- [ ] **AC6:** Layout responsivo — em mobile a coluna não quebra o layout (pode ser ocultada em telas pequenas com `hidden sm:table-cell`)

---

## Análise Técnica

### Método disponível no model

```ruby
# Task#calculated_value — já existe
def calculated_value
  return 0 unless company&.hourly_rate
  company.hourly_rate * total_hours
end
```

> `total_hours` usa `task_items.sum(:hours_worked)` — com `includes(:task_items)` no controller, sem N+1.

### Formatação

Usar o mesmo padrão da listagem `/tasks`:

```erb
<%= number_to_currency(task.calculated_value, unit: "R$", separator: ",", delimiter: ".") %>
```

### Dashboard — `_task_row.html.erb`

Adicionar `<td>` entre a coluna Est/Real e a coluna de ações:

```erb
<td class="px-4 py-3 text-sm text-gray-300">
  <%= number_to_currency(task.calculated_value, unit: "R$", separator: ",", delimiter: ".") %>
</td>
```

### Dashboard — cabeçalho da tabela

O cabeçalho da tabela de tasks do dashboard está em `app/views/dashboard/index.html.erb`. Adicionar `<th>Valor</th>` alinhado com a nova coluna.

---

## Arquivos a Modificar

| Arquivo | Ação |
|---------|------|
| `app/views/dashboard/_task_row.html.erb` | Adicionar `<td>` com `calculated_value` entre Est/Real e ações |
| `app/views/dashboard/index.html.erb` | Adicionar `<th>Valor</th>` no cabeçalho da tabela |
| `app/views/tasks/index.html.erb` | Verificar consistência da coluna "Valor" existente no `TaskCardComponent` |

---

## Testes

- [ ] Dashboard renderiza coluna Valor com valor correto para task com task_items
- [ ] Dashboard exibe `R$ 0,00` para task sem task_items
- [ ] Cabeçalho da tabela inclui coluna "Valor"
- [ ] Sem regressão nos specs existentes de `dashboard_tasks_month_spec.rb`

---

## Dependências

- `Task#calculated_value` — **já existe**
- `includes(:company, :task_items)` no `DashboardController#index` — verificar se `task_items` já está incluído (necessário para `total_hours`)
- `number_to_currency` helper — **já disponível** no Rails

---

## Estimativa

**0,5 story points** (~1h) — adição cirúrgica de uma célula no partial e cabeçalho da tabela.
