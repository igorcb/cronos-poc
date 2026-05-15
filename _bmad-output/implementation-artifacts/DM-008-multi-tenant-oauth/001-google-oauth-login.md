# Story 9.1: Login via Google OAuth (Substituir Email/Senha)

**Status:** ready-for-dev
**Domínio:** DM-008-multi-tenant-oauth
**Data:** 2026-05-15
**Epic:** Epic 9 — Multi-Tenancy & Google OAuth
**Story ID:** 9.1
**Story Key:** 9-1-google-oauth-login
**Prioridade:** critical

---

## Contexto

O sistema está estável e pronto para abrir para novos usuários. Para isso, autenticação via email/senha (atual: `has_secure_password` no `User`) é fricção desnecessária — exige criar/lembrar senha, recuperação por email, etc.

Esta story substitui o login por email/senha por **OAuth Google self-service**: qualquer pessoa com conta Google pode entrar; no primeiro login um `User` é criado automaticamente.

**Importante:** esta story trata APENAS da autenticação. O isolamento de dados por usuário (multi-tenancy) é tratado na story 9.2. Onboarding pós-login na story 9.3.

---

## História do Usuário

**Como** novo usuário,
**Quero** entrar no Cronos POC usando minha conta Google com um clique,
**Para** não precisar criar senha nem preencher formulário de cadastro.

---

## Critérios de Aceite

### AC1 — OAuth Google funcional
- [ ] **AC1.1:** Tela `/login` exibe **apenas** botão "Entrar com Google" (form de email/senha removido)
- [ ] **AC1.2:** Click no botão → redirect para Google OAuth consent screen
- [ ] **AC1.3:** Após autorizar, Google redireciona para callback `/auth/google_oauth2/callback`
- [ ] **AC1.4:** App cria ou atualiza um `User` baseado nos dados do Google (email, google_uid, name, avatar_url)
- [ ] **AC1.5:** Sessão criada → redirect para `/` (dashboard)

### AC2 — Model User estendido
- [ ] **AC2.1:** Migration adiciona colunas: `google_uid` (string, unique, indexed), `name` (string), `avatar_url` (string, nullable)
- [ ] **AC2.2:** Migration **remove** colunas: `password_digest` (após confirmação de que ninguém mais usa senha)
- [ ] **AC2.3:** Model `User` remove `has_secure_password` e validações de senha
- [ ] **AC2.4:** Método de classe `User.from_google_omniauth(auth)` que faz `find_or_create_by(google_uid: ...)` e atualiza `email`, `name`, `avatar_url`

### AC3 — Configuração OAuth
- [ ] **AC3.1:** Gem `omniauth-google-oauth2` adicionada ao Gemfile
- [ ] **AC3.2:** Gem `omniauth-rails_csrf_protection` (proteção CSRF obrigatória em Rails 7+)
- [ ] **AC3.3:** Initializer `config/initializers/omniauth.rb` com `provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"]`
- [ ] **AC3.4:** ENV vars documentadas no `.env.example` (criar se não existir): `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`
- [ ] **AC3.5:** README atualizado com passos para criar OAuth app no Google Cloud Console

### AC4 — Controller OAuth
- [ ] **AC4.1:** `OmniauthCallbacksController` com action `google_oauth2`
- [ ] **AC4.2:** Em caso de sucesso: `User.from_google_omniauth(request.env["omniauth.auth"])` → cria session → redirect para `/`
- [ ] **AC4.3:** Em caso de falha: redirect para `/login` com flash de erro
- [ ] **AC4.4:** Rota `get "/auth/:provider/callback", to: "omniauth_callbacks#:provider"`

### AC5 — Logout
- [ ] **AC5.1:** Botão "Sair" continua funcionando — apenas destrói a sessão local (não revoga token Google)
- [ ] **AC5.2:** Após logout, próximo acesso a rota protegida → redirect para `/login`

### AC6 — Migração do user admin atual
- [ ] **AC6.1:** Seed/migration **não deleta** user admin atual — apenas remove `password_digest`
- [ ] **AC6.2:** Quando admin logar via Google pela primeira vez com mesmo email (`admin@cronos-poc.local` se possível, ou outro), `User.from_google_omniauth` faz **`find_or_create_by(email:)`** e atualiza com `google_uid` — preservando ID e dados associados
- [ ] **AC6.3:** Story 9.2 (multi-tenancy) cuidará do backfill de Companies/Projects/Tasks/TaskItems para este user

### AC7 — Cobertura de testes
- [ ] **AC7.1:** Spec `User.from_google_omniauth` — cria user novo
- [ ] **AC7.2:** Spec `User.from_google_omniauth` — atualiza user existente (mesmo google_uid)
- [ ] **AC7.3:** Spec `User.from_google_omniauth` — encontra por email se google_uid não existe (caso admin atual)
- [ ] **AC7.4:** Request spec `GET /auth/google_oauth2/callback` mockado com OmniAuth.test_mode = true → 302 para `/`
- [ ] **AC7.5:** Specs antigos de login por senha removidos ou desativados

---

## Análise Técnica

### Migration

```ruby
class AddGoogleOauthToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :google_uid, :string
    add_column :users, :name, :string
    add_column :users, :avatar_url, :string
    add_index :users, :google_uid, unique: true

    # password_digest removido em migration separada após confirmação:
    # remove_column :users, :password_digest, :string
  end
end
```

### Model User

```ruby
class User < ApplicationRecord
  # has_secure_password REMOVIDO

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

### View `sessions/new.html.erb` (substituir form)

```erb
<div class="max-w-md mx-auto mt-20">
  <h1 class="text-2xl text-white mb-6">Entrar no Cronos POC</h1>
  <%= button_to "/auth/google_oauth2",
        method: :post,
        data: { turbo: false },
        class: "w-full flex items-center justify-center gap-3 bg-white text-gray-900 ..." do %>
    <%= image_tag "google_g.svg", class: "w-5 h-5" %>
    Entrar com Google
  <% end %>
</div>
```

---

## Arquivos a Criar/Modificar

| Arquivo | Ação |
|---------|------|
| `Gemfile` | Adicionar `omniauth-google-oauth2`, `omniauth-rails_csrf_protection` |
| `config/initializers/omniauth.rb` | Configurar provider Google |
| `config/routes.rb` | Adicionar callback OAuth, remover routes de signup |
| `db/migrate/YYYYMMDD_add_google_oauth_to_users.rb` | Migration colunas Google |
| `db/migrate/YYYYMMDD_remove_password_digest_from_users.rb` | Migration drop senha (após validação) |
| `app/models/user.rb` | Remover `has_secure_password`, adicionar `from_google_omniauth` |
| `app/controllers/omniauth_callbacks_controller.rb` | Criar |
| `app/controllers/sessions_controller.rb` | Remover `#create` (login senha); manter `#destroy` |
| `app/views/sessions/new.html.erb` | Substituir form por botão "Entrar com Google" |
| `app/views/passwords/*` | Remover (esqueci senha não faz sentido) |
| `.env.example` | Criar com `GOOGLE_CLIENT_ID=`, `GOOGLE_CLIENT_SECRET=` |
| `README.md` | Documentar setup OAuth (Google Cloud Console) |
| `spec/models/user_spec.rb` | Specs `from_google_omniauth` |
| `spec/requests/omniauth_callbacks_spec.rb` | Specs callback OAuth (OmniAuth.test_mode) |
| `spec/system/login_spec.rb` | System test "Entrar com Google" mockado |

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

- **Lock-out do admin:** se o email Google do Igor não bater com `admin@cronos-poc.local`, ele perde acesso ao histórico. **Mitigação:** AC6.2 faz lookup por email antes de criar; se ainda assim falhar, criar rake task `users:link_to_google EMAIL=... GOOGLE_UID=...` para vincular manualmente.
- **CSRF:** OmniAuth 2.x exige `omniauth-rails_csrf_protection` — sem ela, links GET `/auth/google_oauth2` não funcionam em produção.

---

## Estimativa

**3 story points** (~5-6h) — gem + migrations + controller + view + 5-7 specs + setup Google Cloud Console + documentação.
