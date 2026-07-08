# Story 1.2: Criar API de autenticação no backend

Status: ready-for-dev

## Story

Como usuário do app mobile,
Eu quero que o backend exponha um endpoint de autenticação que emita um token de API,
so that o app possa me autenticar sem depender de sessão por cookie.

## Acceptance Criteria

**Given** um usuário já autenticado via Google OAuth na web
**When** o app envia as credenciais/código OAuth para `POST /api/v1/sessions`
**Then** o backend valida o usuário e retorna um token de API válido com data de expiração
**And** o token é persistido numa tabela `api_tokens` associada ao usuário
**And** a rota não herda de `ApplicationController` da web (namespace `Api::V1::` isolado)
**And** specs cobrindo esse endpoint existem em `spec/requests/api/v1/sessions_spec.rb`, sem alterar specs existentes

## Tasks / Subtasks

- [ ] Criar migration `CreateApiTokens` (AC: #3)
  - [ ] `create_table :api_tokens, if_not_exists: true` (padrão obrigatório do projeto)
  - [ ] `t.references :user, null: false, foreign_key: true, if_not_exists: true`
  - [ ] `t.string :token, null: false` + índice único (`add_index :api_tokens, :token, unique: true, if_not_exists: true`)
  - [ ] `t.datetime :expires_at, null: false`
  - [ ] timestamps
- [ ] Criar model `ApiToken` (app/models/api_token.rb) (AC: #3)
  - [ ] `belongs_to :user`
  - [ ] `attr_readonly :user_id` (padrão multi-tenant do projeto)
  - [ ] gerar `token` automaticamente no `before_create` (`SecureRandom.hex(32)` ou similar) — nunca aceitar token vindo de params
  - [ ] scope/método `valid` ou `active?` que checa `expires_at > Time.current`
- [ ] Criar `Api::V1::BaseController` (AC: #2, #4)
  - [ ] Não herdar de `ApplicationController` — herdar de `ActionController::API` ou `ActionController::Base` isolado, conforme decisão da arquitetura
  - [ ] `before_action :authenticate_via_token!` que lê `Authorization: Bearer <token>`, busca `ApiToken` válido, seta `Current.user`
  - [ ] token ausente/inválido/expirado → `401` com corpo `{ "error": "..." }`
- [ ] Criar `Api::V1::SessionsController#create` (AC: #1, #2)
  - [ ] `POST /api/v1/sessions` recebe credencial/código OAuth do Google
  - [ ] Valida o usuário (reaproveitar lógica de resolução de usuário do OmniAuth já usada na web — não duplicar)
  - [ ] Cria um `ApiToken` novo para o usuário com `expires_at` definido (ex: 90 dias, ajustável)
  - [ ] Retorna JSON `{ "token": "...", "expires_at": "..." }` (snake_case, sem wrapper `data`)
- [ ] Adicionar rota em `config/routes.rb` (AC: #2)
  - [ ] `namespace :api do namespace :v1 do resource :sessions, only: [:create] end end`
- [ ] Escrever specs em `spec/requests/api/v1/sessions_spec.rb` (AC: #5)
  - [ ] Caso feliz: credencial válida → 201/200 + token retornado + registro em `api_tokens`
  - [ ] Caso de erro: credencial inválida → 401 + `{ "error": "..." }`
  - [ ] Confirmar que nenhum spec existente foi alterado/quebrado

## Dev Notes

### EPIC CONTEXT: Epic 1 — Fundação e Autenticação (DM-013)

Esta é a **segunda story do epic** e a primeira a tocar o backend Rails. Depende apenas da Story 1.1 (projeto mobile existir) — não bloqueia nem é bloqueada por ela tecnicamente (podem ser feitas em paralelo, mas a ordem no backlog é 1.1 → 1.2).

**Decisão arquitetural crítica (ver architecture-mobile.md §Authentication & Security):**
Token **opaco** (não JWT), gerado no backend, armazenado em tabela dedicada `api_tokens`. Motivo: evita complexidade de assinatura/revogação de JWT desnecessária numa POC pequena; revogação é um simples `destroy` da linha.

**Isolamento do namespace da API (arquitetura §API & Communication Patterns):**
`Api::V1::` **não deve herdar de `ApplicationController`** da web — isso evita acoplamento com sessão cookie e protege os 1.120 specs existentes de regressão. Esta é a decisão mais crítica desta story: qualquer herança acidental de `ApplicationController` quebra o isolamento pretendido.

**Multi-tenancy (Defense in Depth, aplicar OBRIGATORIAMENTE):**
```ruby
# ApiToken
belongs_to :user
attr_readonly :user_id
```
Strong params NUNCA devem aceitar `token` ou `user_id` vindos do client — o token é sempre gerado server-side.

### Format Patterns (obrigatório, ver architecture-mobile.md §Format Patterns)

- JSON em snake_case, sem wrapper `{data: ...}`
- Erros: `{ "error": "mensagem legível" }`
- Datas em ISO 8601

### Gap conhecido (não bloqueante, decisão desta story)

A arquitetura deixou em aberto o mecanismo exato de "troca OAuth → token de API" (ver architecture-mobile.md §Gap Analysis Results). Esta story decide isso na implementação: o app mobile deve completar o fluxo OAuth do Google (via `expo-auth-session` ou equivalente, decisão da Story 1.3) e enviar ao backend um identificador confiável do usuário (ex: `id_token` do Google) para `POST /api/v1/sessions`, que o backend valida contra a API do Google ou reaproveita o fluxo `omniauth-google-oauth2` já existente antes de emitir o `ApiToken`.

### Project Structure Notes

```
app/controllers/api/v1/base_controller.rb
app/controllers/api/v1/sessions_controller.rb
app/models/api_token.rb
config/routes.rb (namespace :api)
spec/requests/api/v1/sessions_spec.rb
```

### References

- [Source: _bmad-output/planning-artifacts/mobile/architecture-mobile.md#Authentication & Security]
- [Source: _bmad-output/planning-artifacts/mobile/architecture-mobile.md#API & Communication Patterns]
- [Source: _bmad-output/planning-artifacts/mobile/architecture-mobile.md#Data Architecture]
- [Source: app/models/user.rb] — model existente de referência para OAuth
- [Source: config/initializers/omniauth.rb ou equivalente] — fluxo OAuth web já configurado, reaproveitar validação de usuário

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
