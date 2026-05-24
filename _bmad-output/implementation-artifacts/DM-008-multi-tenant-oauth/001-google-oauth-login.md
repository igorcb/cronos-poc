# Story 9.1: Login via Google OAuth (Adicional ao Email/Senha)

**Status:** done
**Domínio:** DM-008-multi-tenant-oauth
**Data:** 2026-05-15 (revisada 2026-05-23)
**Epic:** Epic 9 — Multi-Tenancy & Google OAuth
**Story ID:** 9.1
**Story Key:** 9-1-google-oauth-login
**Prioridade:** critical

---

## Contexto

O sistema está estável e pronto para abrir para novos usuários. Para reduzir fricção de cadastro, adiciona-se **OAuth Google self-service** como **opção alternativa** ao login por email/senha existente — usuários podem escolher entrar com Google (um clique) ou continuar usando credenciais clássicas.

**Decisão (2026-05-23):** seguir o padrão da maioria dos apps — manter ambos os métodos coexistindo. OAuth Google é **adição**, não substituição. `has_secure_password`, `password_digest` e fluxo de password reset permanecem intactos.

**Importante:** esta story trata APENAS da autenticação. O isolamento de dados por usuário (multi-tenancy) é tratado na story 9.2. Onboarding pós-login na story 9.3.

---

## História do Usuário

**Como** usuário (novo ou existente),
**Quero** entrar no Cronos POC usando minha conta Google com um clique **ou** continuar usando email/senha,
**Para** ter flexibilidade na forma de autenticação sem perder o método atual.

---

## Critérios de Aceite

### AC1 — OAuth Google funcional (adicional ao login email/senha)
- [x] **AC1.1:** Tela `/login` exibe o form de email/senha existente **e** o botão "Entrar com Google", separados por divisor visual ("ou")
- [x] **AC1.2:** Click no botão Google → redirect para Google OAuth consent screen
- [x] **AC1.3:** Após autorizar, Google redireciona para callback `/auth/google_oauth2/callback`
- [x] **AC1.4:** App cria ou atualiza um `User` baseado nos dados do Google (email, google_uid, name, avatar_url)
- [x] **AC1.5:** Sessão criada → redirect para `/` (dashboard)
- [x] **AC1.6:** Se `ENV["GOOGLE_CLIENT_ID"]` não estiver configurada, o botão Google **não é renderizado** (graceful degradation — evita link quebrado em ambientes sem credenciais)

### AC2 — Model User estendido (adicional, sem remoções)
- [x] **AC2.1:** Migration adiciona colunas: `google_uid` (string, unique, indexed), `name` (string), `avatar_url` (string, nullable)
- [x] **AC2.2:** `password_digest` **permanece** — login por senha continua funcionando lado-a-lado com OAuth
- [x] **AC2.3:** Model `User` **mantém** `has_secure_password` e validações de senha existentes; adiciona apenas validação `validates :google_uid, uniqueness: true, allow_nil: true`
- [x] **AC2.4:** Método de classe `User.from_google_omniauth(auth)` que busca por `google_uid` → fallback por email → cria se não existir; atualiza `email`, `name`, `avatar_url`, `google_uid`. Para usuário criado via OAuth sem senha, `password_digest` fica nulo (validar que `has_secure_password` permite isso ou tornar opcional)

### AC3 — Configuração OAuth
- [x] **AC3.1:** Gem `omniauth-google-oauth2` adicionada ao Gemfile
- [x] **AC3.2:** Gem `omniauth-rails_csrf_protection` (proteção CSRF obrigatória em Rails 7+)
- [x] **AC3.3:** Initializer `config/initializers/omniauth.rb` com `provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"]`
- [x] **AC3.4:** ENV vars documentadas no `.env.example` (criar se não existir): `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`
- [x] **AC3.5:** README atualizado com passos para criar OAuth app no Google Cloud Console

### AC4 — Controller OAuth
- [x] **AC4.1:** `OmniauthCallbacksController` com action `google_oauth2`
- [x] **AC4.2:** Em caso de sucesso: `User.from_google_omniauth(request.env["omniauth.auth"])` → cria session → redirect para `/`
- [x] **AC4.3:** Em caso de falha: redirect para `/login` com flash de erro
- [x] **AC4.4:** Rota `get "/auth/:provider/callback", to: "omniauth_callbacks#:provider"`

### AC5 — Logout
- [x] **AC5.1:** Botão "Sair" continua funcionando — apenas destrói a sessão local (não revoga token Google)
- [x] **AC5.2:** Após logout, próximo acesso a rota protegida → redirect para `/login`

### AC6 — Coexistência com user admin atual
- [x] **AC6.1:** User admin (`admin@cronos-poc.local`) **permanece intacto** — pode continuar logando com email/senha
- [x] **AC6.2:** Quando admin (ou qualquer user existente) logar via Google pela primeira vez com o mesmo email, `User.from_google_omniauth` faz lookup por email, vincula `google_uid` e atualiza `name`/`avatar_url` — preservando ID, `password_digest` e dados associados
- [x] **AC6.3:** Story 9.2 (multi-tenancy) cuidará do backfill de Companies/Projects/Tasks/TaskItems para este user

### AC7 — Cobertura de testes
- [x] **AC7.1:** Spec `User.from_google_omniauth` — cria user novo (sem `password_digest`)
- [x] **AC7.2:** Spec `User.from_google_omniauth` — atualiza user existente (mesmo google_uid)
- [x] **AC7.3:** Spec `User.from_google_omniauth` — encontra por email se google_uid não existe (caso admin atual), preserva `password_digest`
- [x] **AC7.4:** Request spec `GET /auth/google_oauth2/callback` mockado com OmniAuth.test_mode = true → 302 para `/`
- [x] **AC7.5:** Specs existentes de login por email/senha **continuam passando** (sessions_controller, passwords) — nenhum spec removido
- [x] **AC7.6:** View spec `sessions/new` cobre os 2 cenários: (a) com `GOOGLE_CLIENT_ID` setada → botão Google + form senha; (b) sem ENV → apenas form senha

---

## Análise Técnica

### Migration (apenas adições)

```ruby
class AddGoogleOauthToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :google_uid, :string
    add_column :users, :name, :string
    add_column :users, :avatar_url, :string
    add_index :users, :google_uid, unique: true
    # password_digest NÃO é removido — login por senha permanece funcional
  end
end
```

### Model User

```ruby
class User < ApplicationRecord
  has_secure_password validations: false  # MANTIDO — senha continua disponível, mas opcional
  # validações de senha aplicadas apenas quando password está sendo definido
  validates :password, length: { minimum: 6 }, if: -> { password.present? }
  validates :password, confirmation: true, if: -> { password.present? }

  validates :email, presence: true, uniqueness: true
  validates :google_uid, uniqueness: true, allow_nil: true

  def self.from_google_omniauth(auth)
    user = find_by(google_uid: auth.uid) || find_or_initialize_by(email: auth.info.email)
    user.assign_attributes(
      google_uid: auth.uid,
      email: auth.info.email,
      name: auth.info.name,
      avatar_url: auth.info.image
    )
    user.save!
    user
  end
end
```

> **Nota:** `has_secure_password validations: false` permite que usuários criados via OAuth não tenham senha. As validações de força/confirmação de senha são reaplicadas condicionalmente — só quando o usuário está definindo/alterando senha. Isso preserva o fluxo `passwords#create/update` existente.

### Controller

```ruby
class OmniauthCallbacksController < ApplicationController
  skip_before_action :require_login, only: :google_oauth2

  def google_oauth2
    user = User.from_google_omniauth(request.env["omniauth.auth"])
    session[:user_id] = user.id
    redirect_to root_path, notice: "Bem-vindo, #{user.name}!"
  rescue StandardError => e
    Rails.logger.error("OAuth failure: #{e.message}")
    redirect_to login_path, alert: "Falha ao autenticar com Google."
  end
end
```

### View `sessions/new.html.erb` (adicionar botão Google ao form existente)

```erb
<div class="max-w-md mx-auto mt-20">
  <h1 class="text-2xl text-white mb-6">Entrar no Cronos POC</h1>

  <%# Form de email/senha existente — MANTIDO %>
  <%= form_with url: login_path, local: true do |f| %>
    <%= f.email_field :email, ... %>
    <%= f.password_field :password, ... %>
    <%= f.submit "Entrar" %>
  <% end %>

  <%# NOVO: botão Google (apenas se credenciais configuradas) %>
  <% if ENV["GOOGLE_CLIENT_ID"].present? %>
    <div class="flex items-center gap-3 my-6">
      <hr class="flex-1 border-gray-700">
      <span class="text-gray-400 text-sm">ou</span>
      <hr class="flex-1 border-gray-700">
    </div>

    <%= button_to "/auth/google_oauth2",
          method: :post,
          data: { turbo: false },
          class: "w-full flex items-center justify-center gap-3 bg-white text-gray-900 ..." do %>
      <%= image_tag "google_g.svg", class: "w-5 h-5" %>
      Entrar com Google
    <% end %>
  <% end %>
</div>
```

---

## Arquivos a Criar/Modificar

| Arquivo | Ação |
|---------|------|
| `Gemfile` | Adicionar `omniauth-google-oauth2`, `omniauth-rails_csrf_protection` |
| `config/initializers/omniauth.rb` | Configurar provider Google (só ativa se ENVs presentes) |
| `config/routes.rb` | Adicionar callback OAuth (rotas de signup/login senha **permanecem**) |
| `db/migrate/YYYYMMDD_add_google_oauth_to_users.rb` | Migration adiciona `google_uid`, `name`, `avatar_url` |
| `app/models/user.rb` | Adicionar `from_google_omniauth`, ajustar `has_secure_password validations: false` + validações condicionais |
| `app/controllers/omniauth_callbacks_controller.rb` | Criar |
| `app/controllers/sessions_controller.rb` | **Não alterar** — `#create` e `#destroy` permanecem |
| `app/views/sessions/new.html.erb` | **Adicionar** divisor "ou" + botão "Entrar com Google" (form de senha permanece) |
| `app/views/passwords/*` | **Não remover** — fluxo de reset de senha permanece ativo |
| `app/assets/images/google_g.svg` | Adicionar ícone oficial do Google |
| `.env.example` | Criar/atualizar com `GOOGLE_CLIENT_ID=`, `GOOGLE_CLIENT_SECRET=` |
| `README.md` | Documentar setup OAuth (Google Cloud Console) |
| `spec/models/user_spec.rb` | Specs `from_google_omniauth` (novo, existente por google_uid, existente por email) |
| `spec/requests/omniauth_callbacks_spec.rb` | Specs callback OAuth (OmniAuth.test_mode) |
| `spec/views/sessions/new_spec.rb` | Cobrir cenários com/sem `GOOGLE_CLIENT_ID` |

---

## Setup Google Cloud Console (documentar no README)

1. Acessar https://console.cloud.google.com/
2. Criar projeto "Cronos POC"
3. APIs & Services → OAuth consent screen
   - External (qualquer Google account)
   - Scopes: `email`, `profile`, `openid`
4. APIs & Services → Credentials → Create Credentials → OAuth 2.0 Client ID
   - Application type: Web application
   - Authorized redirect URIs:
     - `http://localhost:3001/auth/google_oauth2/callback` (dev)
     - `https://cronos.dominio.com/auth/google_oauth2/callback` (prod)
5. Copiar Client ID e Client Secret para `.env`

---

## Dependências

- **Bloqueia:** stories 9.2 (multi-tenancy) e 9.3 (onboarding)
- **Requer:** acesso ao Google Cloud Console para gerar credenciais OAuth

---

## Riscos

- **Lock-out do admin:** mitigado — login por email/senha continua funcionando. Admin pode continuar usando credenciais clássicas mesmo sem OAuth configurado.
- **CSRF:** OmniAuth 2.x exige `omniauth-rails_csrf_protection` — sem ela, links GET `/auth/google_oauth2` não funcionam em produção. Mitigado por AC3.2.
- **`has_secure_password` com password opcional:** ao usar `validations: false` precisamos reimplementar validações de comprimento/confirmação condicionalmente. Mitigação: spec dedicado garantindo que (a) usuário OAuth pode ser criado sem senha; (b) usuário definindo senha ainda passa pelas validações.
- **Botão Google quebrado sem credenciais:** mitigado por AC1.6 (renderiza só se `ENV["GOOGLE_CLIENT_ID"].present?`).

---

## Estimativa

**3 story points** (~5-6h) — gem + migration aditiva + controller OAuth + ajuste de view + 6-8 specs + setup Google Cloud Console (documentação) + ajuste em `has_secure_password` para suportar senha opcional.

---

## Dev Agent Record

**Agente:** Amelia (bmad-agent-dev)
**Data execução:** 2026-05-23
**Branch:** `feature-001-google-oauth-login`
**Status final:** done

### Decisões técnicas tomadas durante a implementação

1. **Migration relaxa `password_digest` NOT NULL** (AC2.2): a tabela original tinha `password_digest :string null: false`. Para suportar usuários OAuth-only (que não definem senha), a migration `20260523104408_add_google_oauth_to_users.rb` executa `change_column_null :users, :password_digest, true`. `password_digest` permanece existindo — apenas deixa de ser obrigatório.

2. **Validações de senha condicionais** (AC2.3): `has_secure_password validations: false` desliga as validações default. Em vez delas, criei:
   - `validates :password, length: { minimum: 8 }, if: -> { password.present? }`
   - `validates :password, confirmation: true, if: -> { password.present? }`
   - `validate :password_required_unless_oauth, on: :create` — exige senha apenas para usuários sem `google_uid` e sem `password_digest` (no create).
   Resultado: usuário OAuth pode ser criado sem senha; admin com senha continua exigindo senha forte.

3. **Initializer monta provider em test mode também**: sem isso, request specs caem em 404 porque o middleware OmniAuth não é registrado quando `GOOGLE_CLIENT_ID` está vazio. Solução: `if Rails.env.test? || ENV present?` com `ENV.fetch(..., "test-client-id")` como fallback. `OmniAuth.config.test_mode = true` nos specs substitui credenciais reais por mocks.

4. **Rota com `match` constrita a `google_oauth2`** em vez de `get "/auth/:provider/callback", to: "..._callbacks#:provider"`: a interpolação `#:provider` no `to:` não funciona em Rails 8 (resultava em 404 mesmo com rota listada). Substituí por rota explícita para `omniauth_callbacks#google_oauth2` com constraint `provider: "google_oauth2"` e via `[:get, :post]` (POST cobre o redirect padrão do OmniAuth com CSRF protection, GET cobre o callback).

5. **Controller usa `start_new_session_for` do concern `Authentication`** (Rails 8 default), não `session[:user_id] = user.id` como sugerido na story. Garante consistência com `SessionsController#create` (mesma factory de session, mesmo cookie signed, mesma associação com `Session.user`).

6. **Flash notice com fallback para email** quando `user.name` é nil — Google às vezes retorna name vazio para contas restritas. `user.name.presence || user.email` evita "Bem-vindo, !".

7. **`OmniAuth.config.allowed_request_methods = [:post]`** + gem `omniauth-rails_csrf_protection` previne CSRF em links GET para `/auth/google_oauth2` (recomendação OmniAuth 2.x).

### Resultado da suite de testes

- **951 examples, 0 failures**
- **Cobertura: 100.0% (667/667 linhas)**
- Comando: `docker exec -e RAILS_ENV=test cronos-poc-web-1 bundle exec rspec`

Specs novos (17 examples adicionados ao total):
- `spec/models/user_spec.rb` — 14 examples cobrindo validações novas (`google_uid` uniqueness, password condicional), `.from_google_omniauth` (3 contextos × 2-3 expectations).
- `spec/requests/omniauth_callbacks_spec.rb` — 6 examples cobrindo callback success (cria user, inicia session, flash com name, fallback para email) + failure path (rescue StandardError) + `/auth/failure`.
- `spec/views/sessions/new.html.erb_spec.rb` — 6 examples cobrindo cenários com e sem `GOOGLE_CLIENT_ID` (graceful degradation AC1.6).

Specs antigos de autenticação executados sem regressão: `sessions_spec.rb` (6), `passwords_spec.rb` (8), `registrations_spec.rb` (4), `authentication_spec.rb` (3) — 21/21 passing.

### File List

**Criados:**
- `db/migrate/20260523104408_add_google_oauth_to_users.rb`
- `config/initializers/omniauth.rb`
- `app/controllers/omniauth_callbacks_controller.rb`
- `app/assets/images/google_g.svg`
- `spec/requests/omniauth_callbacks_spec.rb`
- `spec/views/sessions/new.html.erb_spec.rb`

**Modificados:**
- `Gemfile` — adicionadas `omniauth-google-oauth2`, `omniauth-rails_csrf_protection`
- `Gemfile.lock` — resolução de dependências
- `app/models/user.rb` — `has_secure_password validations: false` + validações condicionais + `.from_google_omniauth` + guards QA (email/uid blank, conflict-aware email, retry RecordNotUnique)
- `app/helpers/application_helper.rb` — `google_oauth_enabled?` helper compartilhado entre view e initializer (QA #4)
- `app/controllers/omniauth_callbacks_controller.rb` — rescues específicos (`OauthInvalidPayloadError`, `RecordInvalid`, `RecordNotUnique`) em vez de `StandardError` genérico (QA #12)
- `app/views/sessions/new.html.erb` — divisor "ou" com `role="separator"` (QA #7) + botão "Entrar com Google" via `google_oauth_enabled?`
- `config/initializers/omniauth.rb` — alinhado ao helper (`CLIENT_ID && CLIENT_SECRET` ambos)
- `config/routes.rb` — rota OAuth callback + failure
- `db/schema.rb` — schema atualizado pela migration
- `spec/models/user_spec.rb` — specs de validações novas + `.from_google_omniauth` + cobertura findings #1/#2/#3/#11 (10 examples adicionais)
- `spec/requests/omniauth_callbacks_spec.rb` — `around` com restore (QA #8/#9) + rescues específicos (QA #12) + logout OAuth (QA #6)
- `spec/views/sessions/new.html.erb_spec.rb` — cobertura `role="separator"` + cenário SECRET parcial (QA #4) + ENVs ambas (helper)
- `spec/requests/accessibility_spec.rb` — botão Google + divisor com semântica acessível (QA #5/#7)
- `spec/requests/mobile_first_spec.rb` — botão Google touch-friendly (QA #5)
- `.env.example` — placeholders `GOOGLE_CLIENT_ID=` e `GOOGLE_CLIENT_SECRET=`
- `.gitignore` — adiciona `.env` ao escopo ignorado
- `docker-compose.yml` — `env_file: - .env` no service `web`
- `README.md` — seção "Google OAuth (Login com Google)" com setup do Google Cloud Console

---

## Review Findings (QA — 2026-05-23)

Code review adversarial via skill `bmad-code-review` (3 lentes: Blind Hunter, Edge Case Hunter, Acceptance Auditor). Total: 15 findings (1 CRITICAL, 5 HIGH, 6 MEDIUM, 3 LOW). Todos registrados em `~/.claude/projects/-home-igor-rails-app-cronos-poc/memory/feedback_qa_9_1_*.md`.

### Aplicados (12)

- [x] **#1 CRITICAL — `email nil sequestra user`**: adicionado `OauthInvalidPayloadError` raise quando `auth.info.email` ou `auth.uid` em branco. Spec: 4 examples cobrindo email nil/blank, uid nil, e que nenhum user é modificado.
- [x] **#2 HIGH — race RecordNotUnique**: retry único após `RecordNotUnique` no `from_google_omniauth`. Spec: simula concorrência via mock e valida retry + re-raise no segundo retry.
- [x] **#3 HIGH — email mudou no Google conflita com outro user**: detecta conflito antes do `assign_attributes` e mantém email antigo (atualiza só google_uid/name/avatar). Spec: 2 examples (conflict vs no-conflict).
- [x] **#4 HIGH — initializer fallback dev + guard desalinhado**: criado `ApplicationHelper.google_oauth_enabled?` usado por view e initializer. View agora exige ambas ENVs (CLIENT_ID + SECRET). Spec: cenário "SECRET missing" → botão não renderiza.
- [x] **#5 HIGH — botão Google sem specs transversais**: 3 specs novos em `accessibility_spec.rb` (aria-hidden no SVG, role=separator no divisor, texto descritivo) + 1 spec em `mobile_first_spec.rb` (min-h-[44px]).
- [x] **#6 HIGH — logout OAuth sem spec**: novo spec `DELETE /session (AC5.1 — logout para user OAuth)` valida logout de user sem `password_digest`.
- [x] **#7 MEDIUM — divisor "ou" com aria-hidden**: trocado wrapper para `role="separator" aria-label="ou"` + aria-hidden nos elementos visuais filhos.
- [x] **#8 MEDIUM — `mock_auth[:provider] = nil`**: trocado para `OmniAuth.config.mock_auth.delete(:google_oauth2)`.
- [x] **#9 MEDIUM — logger sem restore**: trocado `before/after` por `around ... ensure` que restaura logger original.
- [x] **#11 MEDIUM — AC6.2 sem assertir id**: adicionados 2 specs explícitos validando `expect(admin.id).to eq(original_id)` para FK safety.
- [x] **#12 MEDIUM — rescue StandardError genérico**: trocado por rescues específicos (`OauthInvalidPayloadError`, `RecordInvalid`, `RecordNotUnique`) com mensagens distintas. Spec: 4 examples cobrindo cada tipo + um valida que `NoMethodError` sobe (não é mais engolido).

### Deferidos (4) — anotados em `_bmad-output/implementation-artifacts/deferred-work.md`

- [x] **#10 MEDIUM — view spec ENV não thread-safe**: defer. Mitigação parcial via `around ... ensure`. Adicionar `ClimateControl` só se habilitar parallel testing. **Reason:** custo > benefício enquanto suite roda sequencial.
- [x] **#13 LOW — Tailwind duplicado no botão Google**: defer. Apenas 2 botões hoje; abstração prematura. Revisitar quando vier 3º. **Reason:** YAGNI.
- [x] **#14 LOW — `change_column_null` lock em prod**: defer. Cronos POC single-user; adotar `strong_migrations` antes de migrar para multi-user. **Reason:** sem prod multi-tenant ainda.
- [x] **#15 LOW — audit/timestamp do link google_uid**: defer. Fora do escopo da story 9.1; tratar como story de observabilidade ou perfil. **Reason:** não bloqueia OAuth funcional.

### Suite final pós-aplicação

- **971 examples, 0 failures**
- **Cobertura: 100.0% (687/687 linhas)**
- Comando: `docker exec -e RAILS_ENV=test cronos-poc-web-1 bundle exec rspec`
