# Story 1.5: Implementar Autenticação Single-User com Rails 8 Generator

Status: ready-for-dev

## Story

**Como** Igor (usuário do sistema),
**Quero** fazer login de forma segura no sistema,
**Para que** apenas eu tenha acesso aos meus dados de timesheet.

## Acceptance Criteria

**Given** que as ferramentas de qualidade estão configuradas

**When** executo `rails generate authentication`

**Then**
1. Model User é criado com has_secure_password
2. Model Session é criado
3. SessionsController é criado com actions new, create, destroy
4. Concern Authentication é criado em app/controllers/concerns/
5. Views de login (sessions/new) são criadas
6. Migrations para users e sessions são criadas
7. Routes para login, logout são configuradas
8. `rails db:migrate` executa sem erros

## Tasks / Subtasks

- [ ] Executar generator de autenticação (AC: #1-7)
  - [ ] `rails generate authentication`
  - [ ] Verificar arquivos gerados

- [ ] Revisar migrations criadas (AC: #8)
  - [ ] Migration CreateUsers
  - [ ] Migration CreateSessions
  - [ ] Adicionar `if_not_exists: true` conforme padrão do projeto
  - [ ] `rails db:migrate`

- [ ] Configurar ApplicationController
  - [ ] Include concern Authentication
  - [ ] Adicionar before_action :require_authentication

- [ ] Testar autenticação
  - [ ] Acessar /login
  - [ ] Verificar que rotas protegidas redirecionam para login

## Dev Notes

### Rails 8 Authentication Generator

O Rails 8 inclui um generator de autenticação que cria:
- Model `User` com `has_secure_password`
- Model `Session` para gerenciar sessões
- `SessionsController` para login/logout
- Concern `Authentication` para controllers
- Views de login
- Routes

### Migration CreateUsers (Ajustada)

```ruby
class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, if_not_exists: true do |t|
      t.string :email, null: false
      t.string :password_digest, null: false

      t.timestamps
    end

    add_index :users, :email, unique: true, if_not_exists: true
  end
end
```

### Migration CreateSessions

```ruby
class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions, if_not_exists: true do |t|
      t.references :user, null: false, foreign_key: true, if_not_exists: true
      t.string :token, null: false
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end

    add_index :sessions, :token, unique: true, if_not_exists: true
  end
end
```

### app/models/user.rb

```ruby
class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
end
```

### app/models/session.rb

```ruby
class Session < ApplicationRecord
  belongs_to :user

  before_create :generate_token

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64
  end
end
```

### app/controllers/concerns/authentication.rb

```ruby
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :set_current_user
    helper_method :current_user, :user_signed_in?
  end

  private

  def set_current_user
    if session[:session_token]
      @current_session = Session.find_by(token: session[:session_token])
      @current_user = @current_session&.user
    end
  end

  def current_user
    @current_user
  end

  def user_signed_in?
    current_user.present?
  end

  def require_authentication
    unless user_signed_in?
      redirect_to login_path, alert: "Você precisa fazer login para acessar esta página"
    end
  end
end
```

### app/controllers/sessions_controller.rb

```ruby
class SessionsController < ApplicationController
  skip_before_action :require_authentication, only: [:new, :create]

  def new
  end

  def create
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      @session = user.sessions.create!(
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )
      session[:session_token] = @session.token

      redirect_to root_path, notice: "Login realizado com sucesso"
    else
      flash.now[:alert] = "Email ou senha inválidos"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if @current_session
      @current_session.destroy
      session.delete(:session_token)
    end

    redirect_to login_path, notice: "Logout realizado com sucesso"
  end
end
```

### app/views/sessions/new.html.erb

```erb
<div class="max-w-md mx-auto mt-8">
  <h1 class="text-2xl font-bold mb-4">Login</h1>

  <% if flash[:alert] %>
    <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
      <%= flash[:alert] %>
    </div>
  <% end %>

  <%= form_with url: login_path, method: :post, class: "space-y-4" do |f| %>
    <div>
      <%= label_tag :email, "Email", class: "block font-medium mb-1" %>
      <%= email_field_tag :email, nil, required: true, class: "w-full px-3 py-2 border rounded" %>
    </div>

    <div>
      <%= label_tag :password, "Senha", class: "block font-medium mb-1" %>
      <%= password_field_tag :password, nil, required: true, class: "w-full px-3 py-2 border rounded" %>
    </div>

    <div>
      <%= submit_tag "Entrar", class: "w-full bg-blue-600 text-white py-2 px-4 rounded hover:bg-blue-700" %>
    </div>
  <% end %>
</div>
```

### config/routes.rb

```ruby
Rails.application.routes.draw do
  # Authentication
  get  'login',  to: 'sessions#new'
  post 'login',  to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'

  # Root
  root 'dashboard#index'
end
```

### app/controllers/application_controller.rb

```ruby
class ApplicationController < ActionController::Base
  include Authentication

  before_action :require_authentication
end
```

### IMPORTANTE: Padrão ARQ18

**SEMPRE usar `if_not_exists: true` nas migrations!**

Todas as migrations devem seguir o padrão:
```ruby
create_table :users, if_not_exists: true do |t|
  # ...
end

add_index :users, :email, if_not_exists: true
add_reference :sessions, :user, foreign_key: true, if_not_exists: true
```

### References

- [Architecture: Decisão 2.1 - Implementação de Autenticação](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md#decisão-21-implementação-de-autenticação)
- [Epics: Story 1.5](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/epics.md#story-15-implementar-autenticacao-single-user-com-rails-8-generator)

## Dev Agent Record

### Completion Notes List
- [ ] rails generate authentication executado
- [ ] Migrations ajustadas com if_not_exists: true
- [ ] rails db:migrate executado
- [ ] ApplicationController inclui Authentication
- [ ] before_action :require_authentication configurado
- [ ] Rota /login acessível
- [ ] Autenticação funcional

### File List
- app/models/user.rb
- app/models/session.rb
- app/controllers/sessions_controller.rb
- app/controllers/concerns/authentication.rb
- app/controllers/application_controller.rb (modificado)
- app/views/sessions/new.html.erb
- db/migrate/xxx_create_users.rb
- db/migrate/xxx_create_sessions.rb
- config/routes.rb (modificado)
