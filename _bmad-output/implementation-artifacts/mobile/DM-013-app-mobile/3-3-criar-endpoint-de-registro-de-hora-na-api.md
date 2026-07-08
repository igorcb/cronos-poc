# Story 3.3: Criar endpoint de registro de hora na API

Status: ready-for-dev

## Story

Como usuário do app mobile,
Eu quero que o backend permita registrar horas trabalhadas via API,
so that eu lance meu tempo sem precisar da web.

## Acceptance Criteria

**Given** um usuário autenticado via token, com uma tarefa existente
**When** o app chama `POST /api/v1/task_items` com a tarefa, horário de início/fim e data
**Then** o `TaskItem` é criado usando o model existente, que calcula `hours_worked` e `value` automaticamente (mesma lógica da web, sem duplicação)
**And** a resposta retorna o totalizador atualizado da tarefa/dashboard
**And** se a tarefa não pertencer ao usuário autenticado, a API retorna 404
**And** specs cobrindo esse endpoint existem em `spec/requests/api/v1/task_items_spec.rb`

## Tasks / Subtasks

- [ ] Criar `Api::V1::TaskItemsController#create` (AC: #1, #2, #4)
  - [ ] Strong params: `task_id`, `start_time`, `end_time`, `work_date` — **nunca** `user_id`
  - [ ] Criar via associação existente (ex: `task.task_items.build(...)`), garantindo que `task` pertence a `Current.user`
  - [ ] Se `task_id` não pertencer ao usuário autenticado: `404`
  - [ ] Reaproveitar o cálculo de `hours_worked`/`value` já existente no model `TaskItem` (`before_save`/callback) — não recalcular no controller
- [ ] Adicionar rota `POST /api/v1/task_items` (AC: #1)
  - [ ] `namespace :api do namespace :v1 do resources :task_items, only: [:create] end end`
- [ ] Retornar totalizador atualizado na resposta (AC: #3)
  - [ ] Incluir o `TaskItem` criado + os totalizadores atualizados (reaproveitar a mesma lógica de cálculo da Story 2.1, chamada internamente — não duplicar)
- [ ] Escrever specs em `spec/requests/api/v1/task_items_spec.rb` (AC: #5)
  - [ ] Caso feliz: `TaskItem` criado, `hours_worked`/`value` calculados corretamente
  - [ ] Caso tarefa de outro usuário: 404
  - [ ] Caso validação falha (ex: `end_time` antes de `start_time`): 422
  - [ ] Caso sem auth: 401

## Dev Notes

### EPIC CONTEXT: Epic 3 — Gestão de Tarefas e Horas (DM-013)

Depende do Epic 1 (auth) e da Story 3.1 (padrão de controller de criação já estabelecido, mesmo tipo de checagem 404 multi-tenant). Não depende da Story 3.4.

**Regra central (cross-cutting concern da arquitetura, ver architecture-mobile.md §Data Architecture):** o cálculo de `hours_worked` e `value` **já existe** no model `TaskItem` (callback `before_save`, ver `app/models/task_item.rb`) — a API apenas invoca a criação normalmente; NUNCA reimplementar essa fórmula no controller da API.

**Resposta com totalizador atualizado:** para atender ao AC #3 sem duplicar lógica, reaproveitar o mesmo método/service usado pela Story 2.1 (`Api::V1::DashboardController`) para montar os totalizadores atualizados e incluí-los na resposta deste endpoint — extrair para um método/serviço compartilhado se ainda não existir, em vez de copiar o código.

**Multi-tenancy:** mesmo padrão 404 (nunca 403) da Story 3.1 — `task` precisa pertencer a `Current.user`.

### Project Structure Notes

```
app/controllers/api/v1/task_items_controller.rb
spec/requests/api/v1/task_items_spec.rb
```

### References

- [Source: app/models/task_item.rb] — cálculo de `hours_worked`/`value` reaproveitado
- [Source: _bmad-output/implementation-artifacts/mobile/DM-013-app-mobile/3-1-criar-endpoint-de-criacao-de-tarefa-na-api.md] — padrão de checagem multi-tenant (404)
- [Source: _bmad-output/implementation-artifacts/mobile/DM-013-app-mobile/2-1-criar-endpoint-de-dashboard-na-api.md] — lógica de totalizadores reaproveitada

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
