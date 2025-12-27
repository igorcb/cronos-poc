# Story 1.3: Configurar RSpec e Factories

Status: ready-for-dev

## Story

**Como** desenvolvedor,
**Quero** configurar framework de testes RSpec,
**Para que** eu possa escrever testes automatizados desde o início.

## Acceptance Criteria

**Given** que o projeto está com Docker configurado

**When** adiciono gems de teste ao Gemfile (rspec-rails, factory_bot_rails, faker, shoulda-matchers, database_cleaner-active_record)

**Then**
1. `bundle install` executa sem erros
2. `rails generate rspec:install` cria estrutura spec/
3. spec/rails_helper.rb está configurado com FactoryBot e Shoulda Matchers
4. `bundle exec rspec` executa sem erros (0 examples, 0 failures)
5. Estrutura de pastas criada: spec/models, spec/requests, spec/system, spec/components

## Tasks / Subtasks

- [ ] Adicionar gems de teste ao Gemfile (AC: #1)
  - [ ] Grupo development, test: rspec-rails, factory_bot_rails, faker
  - [ ] Grupo test: shoulda-matchers, database_cleaner-active_record
  - [ ] `bundle install`

- [ ] Instalar e configurar RSpec (AC: #2-3)
  - [ ] `rails generate rspec:install`
  - [ ] Configurar FactoryBot em spec/rails_helper.rb
  - [ ] Configurar Shoulda Matchers em spec/rails_helper.rb
  - [ ] Configurar Database Cleaner

- [ ] Criar estrutura de diretórios (AC: #5)
  - [ ] spec/models/
  - [ ] spec/requests/
  - [ ] spec/system/
  - [ ] spec/components/
  - [ ] spec/factories/
  - [ ] spec/support/

- [ ] Testar configuração (AC: #4)
  - [ ] `bundle exec rspec` roda sem erros
  - [ ] Criar spec de exemplo e verificar execução

## Dev Notes

### Gemfile - Adicionar Gems

```ruby
group :development, :test do
  gem 'rspec-rails', '~> 6.1'
  gem 'factory_bot_rails', '~> 6.4'
  gem 'faker', '~> 3.2'
  gem 'pry-rails'
end

group :test do
  gem 'shoulda-matchers', '~> 6.0'
  gem 'database_cleaner-active_record', '~> 2.1'
  gem 'capybara'
  gem 'selenium-webdriver'
end
```

### spec/rails_helper.rb - Configuração Completa

```ruby
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort("Running in production!") if Rails.env.production?
require 'rspec/rails'

# Load support files
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # FactoryBot
  config.include FactoryBot::Syntax::Methods

  # Database Cleaner
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  # Use transactional fixtures
  config.use_transactional_fixtures = true

  # Infer spec type from file location
  config.infer_spec_type_from_file_location!

  # Filter Rails gems in backtraces
  config.filter_rails_from_backtrace!
end

# Shoulda Matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
```

### spec/support/factory_bot.rb

```ruby
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
```

### Exemplo de Factory

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { "password123" }
    password_confirmation { "password123" }
  end
end
```

### Exemplo de Model Spec

```ruby
# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:email) }
  end

  describe 'factory' do
    it 'creates valid user' do
      user = build(:user)
      expect(user).to be_valid
    end
  end
end
```

### .rspec Configuration

```
--require spec_helper
--format documentation
--color
```

### Comandos RSpec

```bash
# Rodar todos os testes
bundle exec rspec

# Rodar spec específico
bundle exec rspec spec/models/user_spec.rb

# Rodar com formato de documentação
bundle exec rspec --format documentation

# Rodar apenas testes que falharam anteriormente
bundle exec rspec --only-failures
```

### References

- [Architecture: Testing Framework](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md#testing-framework)
- [Epics: Story 1.3](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/epics.md#story-13-configurar-rspec-e-factories)

## Dev Agent Record

### Completion Notes List
- [ ] Gems adicionadas ao Gemfile
- [ ] bundle install executado
- [ ] rails generate rspec:install executado
- [ ] FactoryBot configurado
- [ ] Shoulda Matchers configurado
- [ ] Database Cleaner configurado
- [ ] Estrutura spec/ criada
- [ ] bundle exec rspec executa (0 examples, 0 failures)

### File List
- Gemfile (modificado)
- spec/rails_helper.rb (criado/modificado)
- spec/spec_helper.rb (criado)
- spec/support/factory_bot.rb (criado)
- .rspec (criado)
