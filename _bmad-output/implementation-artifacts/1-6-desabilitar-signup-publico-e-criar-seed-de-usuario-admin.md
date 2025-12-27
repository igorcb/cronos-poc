# Story 1.6: Desabilitar Signup Público e Criar Seed de Usuário Admin

Status: ready-for-dev

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

- [ ] Desabilitar signup público (AC: #1)
  - [ ] Remover ou bloquear RegistrationsController
  - [ ] Remover rotas de signup (se existirem)
  - [ ] Ou redirecionar /signup para /login

- [ ] Criar seed de usuário admin (AC: #2-4)
  - [ ] Editar db/seeds.rb
  - [ ] Usar ENV['ADMIN_EMAIL'] e ENV['ADMIN_PASSWORD']
  - [ ] Usar find_or_create_by! para idempotência
  - [ ] Testar: rails db:seed

- [ ] Criar arquivo .env.development (AC: #2)
  - [ ] Adicionar ADMIN_EMAIL e ADMIN_PASSWORD
  - [ ] Adicionar .env* ao .gitignore

- [ ] Testar login completo (AC: #5-6)
  - [ ] Fazer login com credenciais admin
  - [ ] Verificar redirecionamento para root_path
  - [ ] Verificar sessão mantida

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

### Completion Notes List
- [ ] Signup público desabilitado
- [ ] db/seeds.rb criado com admin user
- [ ] .env.development criado
- [ ] .env* adicionado ao .gitignore
- [ ] .env.example criado para documentação
- [ ] dotenv-rails gem instalada
- [ ] rails db:seed executado com sucesso
- [ ] Login funcional com credenciais admin
- [ ] README.md atualizado com instruções

### File List
- db/seeds.rb
- .env.development (criado, não versionado)
- .env.example (criado, versionado)
- .gitignore (modificado)
- Gemfile (modificado)
- config/routes.rb (modificado)
- app/controllers/registrations_controller.rb (modificado ou removido)
- README.md (modificado)
