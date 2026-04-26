# Story 5.11: Botão Entregar Task no Dashboard

**Status:** done
**Domínio:** DM-005-visualizacao-totalizadores
**Data:** 2026-04-24
**Epic:** Epic 5 — Visualização & Dashboard
**Story ID:** 5.11
**Story Key:** 5-11-botao-entregar-task-no-dashboard

---

## Contexto

O dashboard exibe uma listagem de tasks do mês com um botão relógio (azul) para lançar horas. O usuário precisa de uma forma rápida de marcar uma task como **Entregue** diretamente da listagem, sem precisar acessar a tela de edição da task.

O modelo `Task` já suporta o status `delivered` e registra automaticamente a `delivery_date` via `before_save :update_delivery_date`.

---

## História do Usuário

**Como** usuário do Cronos POC,
**Quero** clicar em um botão check ao lado do relógio na listagem do dashboard,
**Para** marcar a task como Entregue diretamente, sem abrir nenhum formulário ou tela separada.

---

## Critérios de Aceite

- [x] **AC1 — Botão check visível:** cada linha da listagem do dashboard exibe um ícone de check (✓) à direita do botão relógio
- [x] **AC2 — Habilitado apenas quando `completed`:** o botão check está clicável (verde) somente quando `task.status == "completed"`; para qualquer outro status, aparece cinza e desabilitado (`disabled`)
- [x] **AC3 — Ação sem confirmação:** ao clicar, envia PATCH direto para `deliver_task_path(task)` sem dialog de confirmação
- [x] **AC4 — Turbo Stream:** após o PATCH bem-sucedido, a linha da task é **removida** da listagem do dashboard via Turbo Stream (sem reload de página)
- [x] **AC5 — Status atualizado:** a task tem seu status alterado para `delivered` e `delivery_date` preenchida automaticamente pelo model
- [x] **AC6 — Botão desabilitado não envia requisição:** status `pending` e `delivered` não disparam ação ao clicar

---

## Análise Técnica

### Rota

Adicionar rota `deliver` no resources tasks:

```ruby
# config/routes.rb
resources :tasks, only: [...] do
  member do
    patch :deliver
  end
  resources :task_items, only: [...]
end
```

### Controller

```ruby
# app/controllers/tasks_controller.rb
def deliver
  @task = Task.find(params[:id])
  @task.update!(status: "delivered")
  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: turbo_stream.remove("task_row_#{@task.id}")
    end
  end
end
```

### Partial `_task_row.html.erb`

Adicionar botão check ao lado do relógio:

```erb
<%# Botão Entregar — habilitado apenas quando completed %>
<% if task.completed? %>
  <%= button_to deliver_task_path(task),
                method: :patch,
                class: "inline-flex items-center justify-center w-8 h-8 bg-green-600 hover:bg-green-500 text-white rounded transition",
                aria: { label: "Marcar #{task.display_name} como entregue" },
                data: { turbo_stream: true } do %>
    <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
    </svg>
  <% end %>
<% else %>
  <span class="inline-flex items-center justify-center w-8 h-8 bg-gray-700 text-gray-500 rounded cursor-not-allowed"
        aria-label="Entregar indisponível — status: <%= task.status %>"
        aria-disabled="true">
    <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
    </svg>
  </span>
<% end %>
```

### ID da linha para remoção Turbo Stream

A `<tr>` em `_task_row.html.erb` precisa de `id`:

```erb
<tr id="task_row_<%= task.id %>" class="hover:bg-gray-700 transition-colors">
```

---

## Arquivos a Modificar

| Arquivo | Ação |
|---------|------|
| `config/routes.rb` | Adicionar `member { patch :deliver }` em resources :tasks |
| `app/controllers/tasks_controller.rb` | Adicionar action `deliver` com resposta Turbo Stream |
| `app/views/dashboard/_task_row.html.erb` | Adicionar `id` na `<tr>` + botão check ao lado do relógio |

---

## Testes

- [x] `spec/requests/tasks_deliver_spec.rb` — PATCH `deliver_task_path` com task `completed` → status 200, Turbo Stream remove linha
- [x] Task `pending` → retorna unprocessable_entity (sem alterar status)
- [x] Task `delivered` → retorna unprocessable_entity (sem alterar status)
- [x] Task `completed` → status atualizado para delivered, delivery_date preenchida, Turbo Stream remove linha

---

## Dependências

- Model `Task` com `status: delivered` e `before_save :update_delivery_date` — **já implementado**
- `_task_row.html.erb` no dashboard — **já existe** (story 5.6)

---

## Estimativa

**1 story point** (~2h) — rota simples, 1 action, ajuste no partial existente.

---

## File List

| Arquivo | Status |
|---------|--------|
| `config/routes.rb` | Modificado |
| `app/controllers/tasks_controller.rb` | Modificado |
| `app/views/dashboard/_task_row.html.erb` | Modificado |
| `spec/requests/tasks_deliver_spec.rb` | Criado |

---

## Dev Agent Record

### Implementation Plan

1. Adicionada rota member `patch :deliver` em resources :tasks no routes.rb
2. Adicionada action `deliver` no TasksController com guard para status != completed (retorna 422), `update!` para `delivered` e resposta turbo_stream removendo `task_row_#{task.id}`
3. Atualizado `_task_row.html.erb`: `<tr>` com id, botão verde `button_to` (completed) e span cinza disabled (outros status)
4. Criado `spec/requests/tasks_deliver_spec.rb` com 12 exemplos cobrindo autenticação, completed, pending e delivered

### Completion Notes

- ✅ AC1: botão check visível em toda linha
- ✅ AC2: botão verde apenas quando completed; span cinza aria-disabled para pending/delivered
- ✅ AC3: button_to sem turbo_confirm — nenhum dialog
- ✅ AC4: turbo_stream.remove("task_row_#{task.id}") — remoção sem reload
- ✅ AC5: update!(status: "delivered") aciona before_save :update_delivery_date do model
- ✅ AC6: pending/delivered retornam 422 sem alterar estado; span não é clicável (não é button_to)
- 12 specs passando, 0 regressões introduzidas (4 falhas pré-existentes confirmadas)

### Change Log

- 2026-04-26: Implementação completa da Story 5.11 — rota deliver, action TasksController#deliver, partial _task_row atualizado, 12 specs criados
