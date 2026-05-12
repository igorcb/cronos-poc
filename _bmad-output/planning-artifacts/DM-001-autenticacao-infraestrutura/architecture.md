# Arquitetura - DM-001: Autenticação & Infraestrutura

**Domínio:** DM-001-autenticacao-infraestrutura
**Tipo:** Transversal / Técnico
**Data:** 2025-12-26 (atualizado 2026-03-27)

## Visão Geral

Este domínio define toda a fundação técnica do Cronos POC: runtime, framework, banco de dados, containerização, ferramentas de qualidade e autenticação. As decisões aqui impactam todos os outros domínios.

## Stack Tecnológico

```
┌─────────────────────────────────────────────┐
│                  Browser                     │
│  Tailwind CSS + Hotwire (Turbo + Stimulus)  │
├─────────────────────────────────────────────┤
│              Rails 8.1.1                     │
│           Ruby 3.4.8 (stable)               │
├─────────────────────────────────────────────┤
│            PostgreSQL 16                     │
├─────────────────────────────────────────────┤
│         Docker + Docker Compose              │
│   web (Rails) + db (PostgreSQL)              │
└─────────────────────────────────────────────┘
```

## Decisões Arquiteturais

### DA-001: Runtime e Framework

| Aspecto | Decisão | Alternativas Descartadas |
|---------|---------|--------------------------|
| Linguagem | Ruby 3.4.8 (stable) | Ruby 4.0.0 (muito novo, pouco testado) |
| Framework | Rails 8.1.1 | Rails 7.x (sem auth generator nativo) |
| Frontend | Hotwire (Turbo + Stimulus) | React/Vue (complexidade desnecessária) |
| CSS | Tailwind CSS 4.x | Bootstrap (menos flexível), CSS puro (lento) |
| JS Bundler | esbuild | Webpack (lento), importmaps (limitado) |
| Asset Pipeline | Propshaft | Sprockets (legado) |

**Justificativa:** Rails com Hotwire elimina SPA e suas complexidades. Server-rendered com interatividade progressiva é a abordagem mais pragmática para uma ferramenta de produtividade single-user.

### DA-002: Banco de Dados

| Aspecto | Decisão | Justificativa |
|---------|---------|---------------|
| Engine | PostgreSQL 16 | Aggregations robustas (SUM, GROUP BY), FK constraints, check constraints |
| ORM | ActiveRecord | Padrão Rails, produtivo, migrations |
| Tipos monetários | `decimal(10,2)` | Precisão financeira, NUNCA Float |

### DA-003: Containerização

```yaml
# docker-compose.yml
services:
  web:
    build: .
    image: ruby:3.4.8-slim
    ports: ["3000:3000"]
    depends_on: [db]
  db:
    image: postgres:16
    volumes: [pgdata:/var/lib/postgresql/data]
```

**Justificativa:** Ambiente reproduzível, isolamento de dependências, fácil onboarding.

### DA-004: Autenticação Single-User

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Browser    │────▶│  Sessions    │────▶│    User      │
│  (Cookie)    │     │  Controller  │     │  (BCrypt)    │
└──────────────┘     └──────────────┘     └──────────────┘
       │                                         │
       │         ┌──────────────┐                │
       └────────▶│  Application │────────────────┘
                 │  Controller  │  before_action
                 │  (Auth Gate) │  :require_authentication
                 └──────────────┘
```

| Aspecto | Decisão | Justificativa |
|---------|---------|---------------|
| Mecanismo | Rails 8 Auth Generator | Built-in, leve, sem gem extra |
| Sessão | Cookie-based | Simples para single-user, sem JWT overhead |
| Signup | Desabilitado | Single-user criado via seed |
| Autorização | Nenhuma gem | Autenticado = autorizado para tudo |
| Secrets | Rails Credentials | Criptografado no repo, `master.key` em .gitignore |

**Seed de Usuário:**
```ruby
User.find_or_create_by!(email: ENV['ADMIN_EMAIL']) do |user|
  user.password = ENV['ADMIN_PASSWORD']
end
```

### DA-005: Ferramentas de Qualidade

| Ferramenta | Propósito | Configuração |
|------------|-----------|--------------|
| RSpec | Testes | `spec/{models,requests,system,components}` |
| FactoryBot | Test data | `spec/factories/` |
| Faker | Dados fake | Usado nas factories |
| Shoulda Matchers | Matchers adicionais | Validações, associações |
| Rubocop + rubocop-rails | Linting | `.rubocop.yml` |
| Bullet | N+1 detection | `config/environments/development.rb` |
| Annotate | Schema docs | Roda após migrations |
| Brakeman | Security scan | CI/CD |

### DA-006: Estrutura de Diretórios

```
cronos-poc/
├── app/
│   ├── controllers/        # CRUD + Dashboard
│   ├── models/             # ActiveRecord + Concerns
│   ├── views/              # ERB templates
│   ├── javascript/
│   │   └── controllers/    # Stimulus controllers
│   ├── components/         # ViewComponents
│   └── services/           # Service Objects
├── config/
│   ├── database.yml
│   ├── routes.rb
│   └── credentials.yml.enc
├── db/migrate/
├── spec/
│   ├── models/
│   ├── requests/
│   ├── system/
│   └── components/
├── Dockerfile
├── docker-compose.yml
└── Procfile.dev
```

## Padrões de Código

| Convenção | Padrão |
|-----------|--------|
| Tabelas | snake_case plural (`time_entries`, `companies`) |
| Colunas | snake_case (`company_id`, `hourly_rate`) |
| Turbo Frames | `resource_action` (`time_entry_form`) |
| Stimulus | `feature_controller.js` (`form_validation_controller.js`) |
| Testes | `spec/{type}/{model}_spec.rb` |
| Código | INGLÊS |
| Documentação | PORTUGUÊS BR |

## Segurança

| Ameaça | Mitigação |
|--------|-----------|
| CSRF | Rails CSRF token (padrão) |
| SQL Injection | ActiveRecord parameterized queries |
| XSS | Rails output escaping (padrão) |
| Secrets expostos | Rails Credentials + .gitignore |
| Acesso não autorizado | `before_action :require_authentication` em ApplicationController |
| Brute force | Rate limiting (futuro) |
