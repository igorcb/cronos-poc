# Story 3.1: Criar endpoint de criação de tarefa na API

Status: ready-for-dev

## Story

Como usuário do app mobile,
Eu quero que o backend permita criar uma tarefa via API,
so that eu registre um novo trabalho sem precisar da web.

## Acceptance Criteria

**Given** um usuário autenticado via token, com ao menos uma empresa/projeto já cadastrados
**When** o app chama `POST /api/v1/tasks` com nome, código e projeto associado
**Then** a tarefa é criada usando o model `Task` existente, aplicando as mesmas validações da web
**And** a resposta retorna a tarefa criada em JSON (snake_case)
**And** se o projeto não pertencer ao usuário autenticado, a API retorna 404 (nunca 403), consistente com a regra multi-tenant da web
**And** specs cobrindo esse endpoint existem em `spec/requests/api/v1/tasks_spec.rb`

## Tasks / Subtasks

- [ ] Implementar `Api::V1::TasksController#create` (AC: #1, #2, #3)
  - [ ] Strong params: `name`, `code`, `project_id` — **nunca** aceitar `user_id`
  - [ ] Criar via `Current.user.tasks.build(task_params)` (ou associação equivalente), garantindo `attr_readonly :user_id` do model `Task` (se já existir) faça seu papel
  - [ ] Reaproveitar as MESMAS validações do model `Task` já usadas na web — nenhuma validação duplicada no controller
  - [ ] Se `project_id` não pertencer ao usuário autenticado: responder `404` (nunca `403`), replicando o padrão já usado na web (ver `belongs_to_current_user` validator, se aplicável a `Task#project`)
  - [ ] Se validação do model falhar (ex: nome em branco): `422` com `{ "error": "..." }`
- [ ] Serializar resposta com `Api::V1::TaskSerializer` (já criado na Story 2.3) (AC: #2)
- [ ] Escrever specs em `spec/requests/api/v1/tasks_spec.rb` (adicionar aos specs já existentes de #index) (AC: #4)
  - [ ] Caso feliz: tarefa criada com sucesso
  - [ ] Caso projeto de outro usuário: 404
  - [ ] Caso validação falha (nome/código ausente): 422
  - [ ] Caso sem auth: 401

## Dev Notes

### EPIC CONTEXT: Epic 3 — Gestão de Tarefas e Horas (DM-013)

Primeira story do Epic 3. Depende do Epic 1 (auth) e do Epic 2 (Story 2.3 — controller `Api::V1::TasksController` e serializer já existem, esta story só adiciona a action `#create`).

**Regra multi-tenant crítica (arquitetura §Data Architecture + padrão geral do projeto):** cross-tenant access **sempre retorna 404, nunca 403** — este é um padrão absoluto do Cronos-POC (ver `implementation-patterns.md` da web). Se o model `Task`/`Project` já usa um validator `belongs_to_current_user` na web, reaproveitar o mesmo mecanismo na API; não inventar uma checagem de autorização paralela.

**Strong params:** jamais permitir `:user_id` vindo do client — regra absoluta do projeto (ver architecture-mobile.md §Enforcement Guidelines e memória do projeto sobre strong params).

**Reaproveitamento:** esta story não cria lógica de validação nova — usa o model `Task` existente tal como está. Se alguma validação da web depender de contexto de sessão/cookie (pouco provável), documentar como issue a resolver, não contornar com lógica duplicada na API.

### Project Structure Notes

```
app/controllers/api/v1/tasks_controller.rb  (adiciona #create)
spec/requests/api/v1/tasks_spec.rb            (adiciona specs de #create)
```

### References

- [Source: app/models/task.rb] — model e validações reaproveitadas
- [Source: _bmad-output/implementation-artifacts/mobile/DM-013-app-mobile/2-3-criar-endpoint-de-listagem-de-tarefas-na-api.md] — controller/serializer já existentes
- [Source: _bmad-output/planning-artifacts/mobile/architecture-mobile.md#Data Architecture]

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
