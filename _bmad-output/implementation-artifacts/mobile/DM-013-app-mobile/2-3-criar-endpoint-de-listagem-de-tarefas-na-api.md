# Story 2.3: Criar endpoint de listagem de tarefas na API

Status: ready-for-dev

## Story

Como usuário do app mobile,
Eu quero que o backend exponha minhas tarefas via API,
so that eu veja quais tarefas existem para lançar horas ou consultar.

## Acceptance Criteria

**Given** um usuário autenticado via token
**When** o app chama `GET /api/v1/tasks`
**Then** o backend retorna as tarefas do usuário (código, nome, status, empresa/projeto associados)
**And** a resposta respeita o isolamento multi-tenant
**And** specs cobrindo esse endpoint existem em `spec/requests/api/v1/tasks_spec.rb`

## Tasks / Subtasks

- [ ] Criar `Api::V1::TasksController#index` (AC: #1, #2)
  - [ ] Herdar de `Api::V1::BaseController`
  - [ ] Escopar `Task.where(user: Current.user)` (ou associação equivalente já usada na web) com `includes` apropriado para evitar N+1 (empresa/projeto)
- [ ] Criar `Api::V1::TaskSerializer` (AC: #1)
  - [ ] Campos: `id`, `code`, `name`, `status`, `company_name`/`company_id`, `project_name`/`project_id` (snake_case)
- [ ] Adicionar rota `GET /api/v1/tasks` (AC: #1)
  - [ ] `namespace :api do namespace :v1 do resources :tasks, only: [:index, :create] end end` (o `:create` é da Story 3.1, mas a rota pode ser declarada junto)
- [ ] Escrever specs em `spec/requests/api/v1/tasks_spec.rb` (AC: #3)
  - [ ] Caso feliz: retorna apenas as tarefas do usuário autenticado
  - [ ] Caso multi-tenant: tarefas de outro usuário nunca aparecem
  - [ ] Caso sem auth: 401
  - [ ] Atenção a N+1 (usar `includes`/`eager_load`, seguindo o padrão já usado na web — ver CLAUDE.md do projeto)

## Dev Notes

### EPIC CONTEXT: Epic 2 — Dashboard Mobile (DM-013)

Depende apenas do Epic 1 (auth). Não depende da Story 2.1/2.2 (endpoint de dashboard é independente da listagem de tarefas) — mas convencionalmente sequenciada depois no backlog.

**Reaproveitamento:** usar a mesma query/scoping já usada em `TasksController#index` da web (ver `app/controllers/tasks_controller.rb`) como referência de eager loading e ordenação — não reinventar a query do zero.

**Performance:** atenção especial a N+1 queries (regra do projeto, ver CLAUDE.md) — usar `includes(:company, :project)` ou equivalente.

**Multi-tenancy:** escopar sempre por `Current.user`, nunca aceitar filtro de usuário vindo de params.

### Project Structure Notes

```
app/controllers/api/v1/tasks_controller.rb
app/serializers/api/v1/task_serializer.rb
spec/requests/api/v1/tasks_spec.rb
```

### References

- [Source: app/controllers/tasks_controller.rb] — query/eager loading de referência
- [Source: _bmad-output/planning-artifacts/mobile/architecture-mobile.md#Data Architecture]
- [Source: _bmad-output/implementation-artifacts/mobile/DM-013-app-mobile/1-2-criar-api-de-autenticacao-no-backend.md] — `Api::V1::BaseController` reaproveitado

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
