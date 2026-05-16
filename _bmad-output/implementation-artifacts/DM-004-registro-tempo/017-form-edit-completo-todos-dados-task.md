# Story 4.17: Exibir Todos os Dados da Tarefa na Tela de Edição

**Status:** done
**Domínio:** DM-004-registro-tempo
**Data:** 2026-05-14
**Epic:** Epic 7 — Edição & Correção
**Story ID:** 4.17
**Story Key:** 4-17-form-edit-completo-todos-dados-task
**Prioridade:** high

---

## Contexto

O form atual de edição (`/tasks/:id/edit`) exibe apenas 7 dos 16 campos da tarefa. Faltam campos importantes para o usuário verificar/conferir todos os dados antes de salvar — principalmente os relacionados a estado (status, delivery_date) e financeiros (hourly_rate, delivered_value), além dos totais de tempo (validated_hours).

Esta story expande o form para mostrar **todos os dados** da tarefa, com regras claras de editável/read-only:

- **Campos editáveis sempre:** `company_id`, `project_id`, `code`, `name`, `estimated_hours`, `start_date`, `end_date`, `notes`, `status`
- **Read-only quando `status: delivered`:** `status` e `delivery_date` (após entrega, esses campos viram imutáveis no form — para alterá-los é preciso usar o botão "Reabrir" da story 4.18)
- **Sempre read-only (calculados/snapshot):** `validated_hours`, `delivery_date`, `hourly_rate`, `delivered_value`, `created_at`, `updated_at`

> Observação: edição de tarefa entregue (`delivered`) tem campos críticos bloqueados. Para alterar qualquer dado financeiro/de entrega é necessário primeiro **reabrir** a tarefa (story 4.18) → ela volta para `completed` e libera os campos.

---

## História do Usuário

**Como** Igor,
**Quero** ver todos os dados da tarefa na tela de edição (estado, totais de tempo, dados financeiros),
**Para** conferir tudo antes de salvar e não precisar abrir múltiplas telas para checar status, horas validadas ou valor da entrega.

---

## Critérios de Aceite

### AC1 — Campos editáveis exibidos no form
- [ ] **AC1.1:** Exibir e permitir editar: `company_id`, `project_id`, `code`, `name`, `estimated_hours`, `start_date`, `end_date`, `notes`, `status`
- [ ] **AC1.2:** Campo `end_date` (data de fim/prazo) — adicionar como `date_field` opcional
- [ ] **AC1.3:** Campo `status` — adicionar como `select` com opções do enum (`pending`, `completed`, `delivered`)

### AC2 — Campos read-only sempre exibidos
- [ ] **AC2.1:** **Dados de tempo (read-only):** exibir bloco "Horas" com:
  - Horas Estimadas (já existe, editável)
  - Horas Validadas (`validated_hours`, formato HH:MM) — read-only
  - Total de Lançamentos (count de `task_items`) — read-only
- [ ] **AC2.2:** **Dados financeiros (read-only):** exibir bloco "Valor" com:
  - Tarifa atual da empresa (`task.company.hourly_rate`) — read-only
  - Tarifa snapshot da entrega (`hourly_rate`) — só aparece quando preenchido
  - Valor acumulado (`total_value` = `SUM(task_items.value)`) — read-only
  - Valor entregue (`delivered_value`) — só aparece quando preenchido
- [ ] **AC2.3:** **Datas (read-only):** exibir `created_at`, `updated_at` formatados em DD/MM/AAAA HH:MM no rodapé do form

### AC3 — Regras quando `status: delivered`
- [ ] **AC3.1:** Campo `status` aparece **disabled** (com hint "Use o botão Reabrir para alterar")
- [ ] **AC3.2:** Campo `delivery_date` aparece **disabled** com valor preenchido
- [ ] **AC3.3:** Demais campos permanecem editáveis (Igor pode corrigir nome/código/projeto de tarefa entregue se necessário)

### AC4 — Layout
- [ ] **AC4.1:** Form organizado em 3 seções visualmente separadas:
  1. **Dados Principais** (empresa, projeto, código, nome, datas, status, observações)
  2. **Horas** (estimadas, validadas, lançamentos) — read-only majoritário
  3. **Financeiro** (tarifa, valor acumulado, valor entregue) — read-only majoritário
- [ ] **AC4.2:** Valores monetários exibidos com `number_to_currency` (R$ 1.234,56)
- [ ] **AC4.3:** Horas exibidas em formato HH:MM (não decimal)

### AC5 — Cobertura
- [ ] **AC5.1:** Request spec GET `/tasks/:id/edit` verifica presença dos novos campos no body
- [ ] **AC5.2:** Request spec PATCH com novos campos (status, end_date) → atualização correta
- [ ] **AC5.3:** Request spec PATCH em task `delivered` tentando alterar status → não muda (campo disabled, params filtrado no controller)
- [ ] **AC5.4:** System spec/Playwright valida exibição read-only dos blocos Horas e Financeiro

---

## Análise Técnica

### Strong params

`TasksController#update` precisa permitir os novos campos editáveis:

```ruby
def task_params
  params.require(:task).permit(:company_id, :project_id, :code, :name,
                               :estimated_hours_hm, :start_date, :end_date,
                               :status, :notes)
end
```

**Importante:** `status` só deve entrar nos params quando o registro **não** for `delivered` — guard no controller:

```ruby
def update
  permitted = task_params
  permitted.delete(:status) if @task.delivered?  # protege snapshot
  if @task.update(permitted)
    ...
  end
end
```

### Layout (sugestão)

```erb
<%= form_with(model: @task, ...) do |f| %>
  <!-- Seção 1: Dados Principais -->
  <fieldset>
    <legend>Dados Principais</legend>
    <!-- company_id, project_id, code, name -->
    <!-- start_date, end_date -->
    <!-- status (disabled se delivered) -->
    <!-- notes -->
  </fieldset>

  <!-- Seção 2: Horas (read-only majoritário) -->
  <fieldset>
    <legend>Horas</legend>
    <!-- estimated_hours_hm (editável) -->
    <!-- validated_hours_hm (read-only) -->
    <!-- task_items.count + link "Ver lançamentos" -->
  </fieldset>

  <!-- Seção 3: Financeiro (read-only) -->
  <fieldset>
    <legend>Financeiro</legend>
    <!-- company.hourly_rate (atual) -->
    <!-- task.hourly_rate (snapshot, se delivered) -->
    <!-- total_value -->
    <!-- delivered_value (se delivered) -->
  </fieldset>

  <!-- Rodapé: timestamps -->
  <p>Criado em: <%= l(@task.created_at, format: :short) %></p>
  <p>Atualizado em: <%= l(@task.updated_at, format: :short) %></p>
<% end %>
```

### Helper para horas

Já existe `validated_hours_hm`? Verificar — se não, adicionar método auxiliar em `Task`:

```ruby
def validated_hours_hm
  return "00:00" if validated_hours.nil? || validated_hours.zero?
  total_minutes = (validated_hours * 60).to_i
  format("%02d:%02d", total_minutes / 60, total_minutes % 60)
end
```

---

## Arquivos a Modificar

| Arquivo | Ação |
|---------|------|
| `app/views/tasks/edit.html.erb` | Expandir form com novos campos + 3 fieldsets |
| `app/controllers/tasks_controller.rb` | Adicionar `status`, `end_date` ao `task_params`; guard delivered |
| `app/models/task.rb` | Adicionar `validated_hours_hm` (se não existir) |
| `spec/requests/tasks_spec.rb` | Specs dos novos campos no GET #edit e PATCH #update |
| `spec/system/tasks_edit_spec.rb` (opcional) | System test dos 3 blocos |

---

## Testes

- [ ] GET `/tasks/:id/edit` para task `pending` — todos os campos editáveis presentes
- [ ] GET `/tasks/:id/edit` para task `delivered` — status e delivery_date `disabled`
- [ ] PATCH `/tasks/:id` com `status: completed` em task `pending` → atualiza
- [ ] PATCH `/tasks/:id` com `status: pending` em task `delivered` → ignora alteração (campo filtrado)
- [ ] PATCH com `end_date` → atualiza
- [ ] Read-only blocks renderizam valores corretos (HH:MM, R$)

---

## Dependências

- Story 4.18 (Reabrir tarefa entregue) — complementar mas pode ser implementada em paralelo
- Stories 4.15 (hourly_rate/value persistidos) e 5.21 (display_value) — **já implementadas**

---

## Estimativa

**2 story points** (~3-4h) — form expandido com 3 fieldsets + helpers de formatação + guard delivered no controller + specs.
