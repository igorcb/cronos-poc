# Story 1.3: Configurar RSpec e Factories

Status: done

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

- [x] Adicionar gems de teste ao Gemfile (AC: #1)
  - [x] Grupo development, test: rspec-rails, factory_bot_rails, faker
  - [x] Grupo test: shoulda-matchers, database_cleaner-active_record
  - [x] `bundle install`

- [x] Instalar e configurar RSpec (AC: #2-3)
  - [x] `rails generate rspec:install`
  - [x] Configurar FactoryBot em spec/rails_helper.rb
  - [x] Configurar Shoulda Matchers em spec/rails_helper.rb
  - [x] Configurar Database Cleaner

- [x] Criar estrutura de diretórios (AC: #5)
  - [x] spec/models/
  - [x] spec/requests/
  - [x] spec/system/
  - [x] spec/components/
  - [x] spec/factories/
  - [x] spec/support/

- [x] Testar configuração (AC: #4)
  - [x] `bundle exec rspec` roda sem erros
  - [x] Criar spec de exemplo e verificar execução

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

### Implementation Plan
- Adicionar gems de teste ao Gemfile (rspec-rails, factory_bot_rails, faker, shoulda-matchers, database_cleaner-active_record, capybara, selenium-webdriver, pry-rails)
- Executar bundle install para instalar as gems
- Gerar estrutura RSpec com rails generate rspec:install
- Configurar FactoryBot, Shoulda Matchers e Database Cleaner no rails_helper.rb
- Criar estrutura de diretórios spec/ (models, requests, system, components, factories, support)
- Configurar .rspec com formato documentation e cores
- Criar banco de dados de teste
- Criar spec de exemplo para validar configuração
- Testar execução com bundle exec rspec

### Completion Notes List
- [x] Gems adicionadas ao Gemfile
- [x] bundle install executado (30 gems instaladas)
- [x] rails generate rspec:install executado
- [x] FactoryBot configurado no rails_helper.rb
- [x] Shoulda Matchers configurado no rails_helper.rb
- [x] Database Cleaner configurado no rails_helper.rb
- [x] Estrutura spec/ criada (models, requests, system, components, factories, support)
- [x] .rspec configurado com --format documentation e --color
- [x] Banco de dados de teste criado (cronos_poc_test)
- [x] spec/models/application_record_spec.rb criado para validação
- [x] bundle exec rspec executa com sucesso (1 example, 0 failures)

### Debug Log
- Criação inicial do banco de teste necessária antes da primeira execução do RSpec
- Comando executado: bin/rails db:create db:migrate RAILS_ENV=test
- RSpec configurado com sucesso com formato documentation e cores ativas

### File List
- Gemfile (modificado - adicionadas gems de teste)
- Gemfile.lock (atualizado)
- .rspec (modificado - adicionado formato e cores)
- db/schema.rb (gerado - schema do banco de teste)
- spec/rails_helper.rb (modificado - configurado FactoryBot, Shoulda Matchers, system tests)
- spec/spec_helper.rb (gerado)
- spec/support/factory_bot.rb (criado)
- spec/models/application_record_spec.rb (criado - teste de exemplo)
- spec/models/ (criado)
- spec/requests/ (criado)
- spec/system/ (criado)
- spec/components/ (criado)
- spec/factories/ (criado)
- spec/support/ (criado)

### Change Log
- 2025-12-27: Configuração completa do RSpec e FactoryBot - Framework de testes pronto para uso
- 2025-12-27: Code Review - Corrigidos 8 problemas (3 HIGH, 5 MEDIUM)

## Senior Developer Review (AI)

**Review Date:** 2025-12-27
**Reviewer:** Code Review Agent (Adversarial)
**Outcome:** ✅ **Approve with Fixes Applied**

### Summary
Code review encontrou 10 issues (3 HIGH, 5 MEDIUM, 2 LOW). Todos os problemas HIGH e MEDIUM foram corrigidos automaticamente. Testes passando: **9 examples, 0 failures**.

### Issues Fixed (8 total)

#### HIGH Priority (3 fixed)
1. ✅ **Configuração Duplicada do FactoryBot** - Removida duplicação entre rails_helper.rb e support/factory_bot.rb
2. ✅ **Conflito Database Cleaner + use_transactional_fixtures** - Removido Database Cleaner (redundante), configurado system tests corretamente
3. ✅ **db/schema.rb não documentado** - Adicionado ao File List

#### MEDIUM Priority (5 fixed)
4. ✅ **Nenhuma factory criada** - Adicionado .gitkeep em spec/factories/ com documentação
5. ✅ **spec/support/factory_bot.rb redundante** - Melhorado com factory linting e comentários
6. ✅ **Teste de exemplo não valida RSpec** - Criado spec/support/rspec_configuration_spec.rb que testa todas as gems
7. ✅ **Faltam .gitkeep files** - Adicionados em spec/requests/, spec/system/, spec/components/, spec/factories/
8. ✅ **Nenhum teste de integração** - Criado teste completo que valida FactoryBot, Faker, Shoulda Matchers, e transactional fixtures

### LOW Priority (não corrigidos)
9. ℹ️ Mensagem de abort genérica - Diferença mínima com Dev Notes (não impacta funcionalidade)
10. ℹ️ Comentários não removidos - Comentário sobre support files ainda presente (baixo impacto)

### Files Changed During Review
- spec/rails_helper.rb (corrigido - removida duplicação FactoryBot, removido Database Cleaner, adicionado config system tests)
- spec/support/factory_bot.rb (melhorado - adicionado factory linting)
- spec/support/rspec_configuration_spec.rb (criado - testes de integração)
- spec/factories/.gitkeep (criado)
- spec/requests/.gitkeep (criado)
- spec/system/.gitkeep (criado)
- spec/components/.gitkeep (criado)

### Test Results
```
9 examples, 0 failures
Finished in 0.26244 seconds
```

### Recommendation
✅ **APPROVED** - Story ready for "done" status. All critical and medium issues resolved, comprehensive test coverage added.
