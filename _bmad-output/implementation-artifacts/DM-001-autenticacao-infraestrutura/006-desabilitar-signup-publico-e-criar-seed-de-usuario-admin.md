# Story 1.6: Desabilitar Signup Público e Criar Seed de Usuário Admin

Status: done

## Story

**Como** Igor,
**Quero** que apenas eu possa acessar o sistema (single-user),
**Para que** não haja risco de outras pessoas criarem contas.

## Acceptance Criteria

**Given** que autenticação Rails 8 está configurada

**When** desabilito signup público no RegistrationsController

**Then**
1. Rota de registro `/signup` redireciona para `/login` com mensagem "Registro desabilitado"
2. db/seeds.rb cria usuário admin com `ENV['ADMIN_EMAIL']` e `ENV['ADMIN_PASSWORD']`
3. `User.find_or_create_by!` garante idempotência do seed
4. `rails db:seed` cria usuário sem erros
5. Consigo fazer login com credenciais do usuário admin
6. Após login, sou redirecionado para root_path

## Tasks / Subtasks

- [x] Desabilitar signup público (AC: #1)
  - [x] Remover ou bloquear RegistrationsController
  - [x] Remover rotas de signup (se existirem)
  - [x] Ou redirecionar /signup para /login

- [x] Criar seed de usuário admin (AC: #2-4)
  - [x] Editar db/seeds.rb
  - [x] Usar ENV['ADMIN_EMAIL'] e ENV['ADMIN_PASSWORD']
  - [x] Usar find_or_create_by! para idempotência
  - [x] Testar: rails db:seed

- [x] Criar arquivo .env.development (AC: #2)
  - [x] Adicionar ADMIN_EMAIL e ADMIN_PASSWORD
  - [x] Adicionar .env* ao .gitignore

- [x] Testar login completo (AC: #5-6)
  - [x] Fazer login com credenciais admin
  - [x] Verificar redirecionamento para root_path
  - [x] Verificar sessão mantida

## Dev Notes

### db/seeds.rb

```ruby
# Create admin user for single-user system
puts "Creating admin user..."

admin_email = ENV.fetch('ADMIN_EMAIL', 'admin@cronos-poc.local')
admin_password = ENV.fetch('ADMIN_PASSWORD', 'password123')

user = User.find_or_create_by!(email: admin_email) do |u|
  u.password = admin_password
  u.password_confirmation = admin_password
end

puts "Admin user created: #{user.email}"
puts "Login at: http://localhost:3000/login"
```

### .env.development

```bash
# Admin User Credentials (Single-User System)
ADMIN_EMAIL=igor@cronos-poc.local
ADMIN_PASSWORD=seu_password_seguro_aqui

# Database
DATABASE_HOST=db
DATABASE_USER=postgres
DATABASE_PASSWORD=postgres
```

### .gitignore (adicionar)

```
# Environment variables
.env*
!.env.example
```

### .env.example (para documentação)

```bash
# Admin User Credentials
ADMIN_EMAIL=your-email@example.com
ADMIN_PASSWORD=your-secure-password

# Database (Docker)
DATABASE_HOST=db
DATABASE_USER=postgres
DATABASE_PASSWORD=postgres
```

### Gemfile - dotenv-rails

```ruby
# Adicionar gem para carregar ENV vars de .env
gem 'dotenv-rails', groups: [:development, :test]
```

Depois: `bundle install`

### Desabilitar Signup

**Opção 1: Remover rotas de signup completamente**

Se o generator Rails 8 authentication criou rotas de signup, remova-as:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Authentication (apenas login/logout, SEM signup)
  get  'login',  to: 'sessions#new'
  post 'login',  to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'

  # Remover ou comentar rotas de signup:
  # get  'signup', to: 'registrations#new'
  # post 'signup', to: 'registrations#create'

  root 'dashboard#index'
end
```

**Opção 2: Redirecionar signup para login**

Se quiser manter a rota mas bloquear acesso:

```ruby
# app/controllers/registrations_controller.rb
class RegistrationsController < ApplicationController
  skip_before_action :require_authentication

  def new
    redirect_to login_path, alert: "Registro público desabilitado. Sistema single-user."
  end

  def create
    redirect_to login_path, alert: "Registro público desabilitado. Sistema single-user."
  end
end
```

### Executar Seed

```bash
# Development
rails db:seed

# Ou resetar tudo
rails db:reset  # DROP, CREATE, MIGRATE, SEED

# Docker
docker-compose exec web rails db:seed
```

### Testar Login

1. Acessar `http://localhost:3000/login`
2. Usar credenciais do .env.development:
   - Email: `igor@cronos-poc.local`
   - Password: (valor de ADMIN_PASSWORD)
3. Submeter form
4. Verificar redirecionamento para root_path
5. Verificar que está autenticado

### IMPORTANTE: Segurança

**NÃO commitar .env com passwords reais!**

- `.env*` deve estar em .gitignore
- Commitar apenas `.env.example` com valores placeholder
- Em produção, usar variáveis de ambiente do servidor/hosting

### README.md - Documentar Setup

Adicionar ao README.md:

```markdown
## Setup

1. Clone repository
2. Copy .env.example to .env.development
3. Edit .env.development with your admin credentials
4. Run: `docker-compose up`
5. Run: `docker-compose exec web rails db:create db:migrate db:seed`
6. Access: http://localhost:3000/login
7. Login with credentials from .env.development
```

### References

- [Architecture: Decisão 2.1 - Autenticação Single-User](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md#customização-para-single-user)
- [Epics: Story 1.6](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/epics.md#story-16-desabilitar-signup-publico-e-criar-seed-de-usuario-admin)

## Dev Agent Record

### Implementation Plan
- Created [RegistrationsController](app/controllers/registrations_controller.rb:1) to redirect signup attempts to login
- Added `/signup` routes in [config/routes.rb:6-7](config/routes.rb#L6-L7) that redirect to login
- Implemented admin user seed in [db/seeds.rb:5-17](db/seeds.rb#L5-L17) using `find_or_create_by!` for idempotency
- Added `dotenv-rails` gem to [Gemfile:59](Gemfile#L59) to load ENV variables
- Created `.env.development` with admin credentials (ADMIN_EMAIL, ADMIN_PASSWORD)
- Created `.env.example` for documentation (committed to git)
- Updated [.gitignore:12](/.gitignore#L12) to allow `.env.example` while blocking other `.env*` files

### Completion Notes
- ✅ Signup público desabilitado via RegistrationsController com redirect e mensagem
- ✅ db/seeds.rb criado com admin user usando ENV vars
- ✅ .env.development criado com credenciais admin
- ✅ .env* adicionado ao .gitignore (com exceção para .env.example)
- ✅ .env.example criado para documentação
- ✅ dotenv-rails gem instalada
- ✅ Testes cobrem: signup redirect, seed idempotency, admin login flow
- ✅ Login funcional com credenciais admin (validado via specs)
- ✅ 38 tests passing, 0 failures

### File List
- app/controllers/registrations_controller.rb (created)
- config/routes.rb (modified)
- db/seeds.rb (modified)
- .env.development (created, not committed)
- .env.example (created, committed)
- .gitignore (modified)
- Gemfile (modified)
- spec/requests/registrations_spec.rb (created)
- spec/db/seeds_spec.rb (created)
- spec/features/admin_login_spec.rb (created)

### Change Log
- **2025-12-27**: Implemented single-user authentication with disabled public signup, admin seed, and environment-based credentials
