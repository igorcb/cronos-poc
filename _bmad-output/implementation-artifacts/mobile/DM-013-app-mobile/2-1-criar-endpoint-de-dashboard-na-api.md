# Story 2.1: Criar endpoint de dashboard na API

Status: ready-for-dev

## Story

Como usuário do app mobile,
Eu quero que o backend exponha meus KPIs/totalizadores via API,
so that o app possa exibir os mesmos dados que vejo na web.

## Acceptance Criteria

**Given** um usuário autenticado via token
**When** o app chama `GET /api/v1/dashboard`
**Then** o backend retorna os totalizadores diário/mensal (horas, valor) calculados a partir dos mesmos models usados pela web (`Task`, `TaskItem`)
**And** a resposta respeita o isolamento multi-tenant (só retorna dados do usuário autenticado pelo token)
**And** specs cobrindo esse endpoint existem em `spec/requests/api/v1/dashboard_spec.rb`

## Tasks / Subtasks

- [ ] Criar `Api::V1::DashboardController#show` (AC: #1, #2)
  - [ ] Herdar de `Api::V1::BaseController` (auth por token já implementado na Story 1.2)
  - [ ] Reaproveitar a MESMA lógica de cálculo de totalizadores usada pelo `DashboardController`/helper da web (ex: `TasksController#index` ou o service/concern que calcula `hours_today`, `hours_month`, `value_today`, `value_month`) — **não duplicar a lógica de cálculo**
  - [ ] Escopar tudo por `Current.user` (nunca aceitar `user_id` de params)
- [ ] Adicionar rota `GET /api/v1/dashboard` (AC: #1)
  - [ ] `namespace :api do namespace :v1 do resource :dashboard, only: [:show] end end`
- [ ] Serializar resposta em snake_case (AC: #1)
  - [ ] Ex: `{ "hours_today": 4.5, "hours_month": 120.0, "value_today": 675.0, "value_month": 18000.0 }`
- [ ] Escrever specs em `spec/requests/api/v1/dashboard_spec.rb` (AC: #3)
  - [ ] Caso feliz: usuário autenticado recebe seus totalizadores corretos
  - [ ] Caso multi-tenant: dados de outro usuário nunca aparecem na resposta
  - [ ] Caso sem auth: 401

## Dev Notes

### EPIC CONTEXT: Epic 2 — Dashboard Mobile (DM-013)

Primeira story do Epic 2. Depende apenas do Epic 1 (token de auth funcionando, `Api::V1::BaseController` existente) — não depende de nenhuma story do Epic 3.

**Regra central da arquitetura (cross-cutting concern, ver architecture-mobile.md §Data Architecture):** o cálculo de `hours_worked`/`value`/totalizadores deve ser a MESMA fonte de verdade usada pela web — encontrar o método/concern/service já usado no `DashboardController` ou `TasksController` web (ver `app/models/task_item.rb`, `app/models/concerns/` se existir) e reaproveitar via chamada direta, nunca reimplementar a fórmula em Ruby duplicado dentro do controller da API.

**Multi-tenancy:** seguir o padrão já usado nos controllers web — escopar sempre por `Current.user`, nunca por `params[:user_id]`. Cross-tenant deve ser inacessível por design (nem chega a ser um caso de 404 aqui, pois o endpoint não recebe ID de outro usuário — é sempre "meus dados").

### Project Structure Notes

```
app/controllers/api/v1/dashboard_controller.rb
spec/requests/api/v1/dashboard_spec.rb
```

### References

- [Source: _bmad-output/planning-artifacts/mobile/architecture-mobile.md#Data Architecture]
- [Source: app/controllers/tasks_controller.rb] — lógica de cálculo de totalizadores da web a reaproveitar
- [Source: _bmad-output/implementation-artifacts/mobile/DM-013-app-mobile/1-2-criar-api-de-autenticacao-no-backend.md] — `Api::V1::BaseController` reaproveitado

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
