# Story 1.4: Configurar Code Quality Tools

Status: ready-for-dev

## Story

**Como** desenvolvedor,
**Quero** configurar ferramentas de qualidade de código,
**Para que** o código siga padrões consistentes e detecte problemas automaticamente.

## Acceptance Criteria

**Given** que RSpec está configurado

**When** adiciono gems de qualidade (rubocop, rubocop-rails, rubocop-rspec, bullet, annotate, pry-rails)

**Then**
1. `bundle install` executa sem erros
2. `.rubocop.yml` está criado com configurações Rails
3. `bundle exec rubocop` executa sem erros críticos
4. Bullet está configurado em config/environments/development.rb para detectar N+1 queries
5. Annotate está configurado para rodar após migrations

## Tasks / Subtasks

- [ ] Adicionar gems ao Gemfile (AC: #1)
  - [ ] Grupo development: rubocop, rubocop-rails, rubocop-rspec, bullet, annotate, pry-rails
  - [ ] `bundle install`

- [ ] Configurar Rubocop (AC: #2-3)
  - [ ] Criar .rubocop.yml
  - [ ] Configurar regras Rails
  - [ ] Executar `bundle exec rubocop --auto-gen-config` se necessário
  - [ ] Testar: `bundle exec rubocop`

- [ ] Configurar Bullet (AC: #4)
  - [ ] Adicionar configuração em config/environments/development.rb
  - [ ] Ativar alerts para N+1 queries
  - [ ] Testar que Bullet está ativo

- [ ] Configurar Annotate (AC: #5)
  - [ ] `rails g annotate:install`
  - [ ] Configurar para rodar após migrations

## Dev Notes

### Gemfile - Code Quality Gems

```ruby
group :development do
  gem 'rubocop', '~> 1.60', require: false
  gem 'rubocop-rails', '~> 2.23', require: false
  gem 'rubocop-rspec', '~> 2.26', require: false
  gem 'bullet', '~> 7.1'
  gem 'annotate', '~> 3.2'
  gem 'pry-rails'
end
```

### .rubocop.yml

```yaml
require:
  - rubocop-rails
  - rubocop-rspec

AllCops:
  NewCops: enable
  TargetRubyVersion: 3.4
  Exclude:
    - 'db/schema.rb'
    - 'db/migrate/*'
    - 'node_modules/**/*'
    - 'bin/*'
    - 'config/**/*'
    - 'vendor/**/*'

# Rails
Rails:
  Enabled: true

# Style
Style/Documentation:
  Enabled: false

Style/StringLiterals:
  EnforcedStyle: single_quotes

# Metrics
Metrics/MethodLength:
  Max: 20

Metrics/BlockLength:
  Exclude:
    - 'spec/**/*'
    - 'config/routes.rb'

# Layout
Layout/LineLength:
  Max: 120
```

### config/environments/development.rb - Bullet

```ruby
Rails.application.configure do
  # ... existing config ...

  # Bullet configuration
  config.after_initialize do
    Bullet.enable = true
    Bullet.alert = true
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.rails_logger = true
    Bullet.add_footer = true
  end
end
```

### Annotate Configuration

```bash
# Gerar configuração
rails g annotate:install

# Isso cria lib/tasks/auto_annotate_models.rake
# Configura para rodar automaticamente após migrations
```

### lib/tasks/auto_annotate_models.rake

```ruby
if Rails.env.development?
  require 'annotate'

  task :set_annotation_options do
    Annotate.set_defaults(
      'models' => 'true',
      'routes' => 'false',
      'position_in_class' => 'before',
      'position_in_factory' => 'before',
      'show_foreign_keys' => 'true',
      'show_indexes' => 'true'
    )
  end

  Annotate.load_tasks
end
```

### Comandos Úteis

```bash
# Rubocop - verificar código
bundle exec rubocop

# Rubocop - auto-corrigir issues seguros
bundle exec rubocop -a

# Rubocop - auto-corrigir tudo (cuidado!)
bundle exec rubocop -A

# Annotate - anotar models manualmente
bundle exec annotate --models

# Pry - debug interativo
# Adicionar `binding.pry` no código
```

### Exemplo de Model Anotado

```ruby
# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  email           :string           not null
#  password_digest :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email  (email) UNIQUE
#
class User < ApplicationRecord
  has_secure_password
  validates :email, presence: true, uniqueness: true
end
```

### References

- [Architecture: Code Quality & Development Tools](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md#code-quality--development-tools)
- [Epics: Story 1.4](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/epics.md#story-14-configurar-code-quality-tools)

## Dev Agent Record

### Completion Notes List
- [ ] Gems de qualidade adicionadas
- [ ] .rubocop.yml criado
- [ ] Rubocop executa sem erros críticos
- [ ] Bullet configurado em development.rb
- [ ] Annotate instalado e configurado
- [ ] Pry-rails disponível para debugging

### File List
- Gemfile (modificado)
- .rubocop.yml (criado)
- config/environments/development.rb (modificado)
- lib/tasks/auto_annotate_models.rake (criado)
