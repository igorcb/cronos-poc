# Cronos POC

[![CI](https://github.com/igorcb/cronos-poc/actions/workflows/ci.yml/badge.svg)](https://github.com/igorcb/cronos-poc/actions/workflows/ci.yml)

Sistema de Gestão de Tempo desenvolvido com Rails 8.1.1, Hotwire e Tailwind CSS.

## 🚀 Stack Tecnológico

- **Ruby** 3.4.8
- **Rails** 8.1.1
- **PostgreSQL** 16
- **Hotwire** (Turbo + Stimulus)
- **Tailwind CSS** 4.x
- **esbuild** (JavaScript bundler)

## 📋 Pré-requisitos

- Docker e Docker Compose
- Git

## 🛠️ Instalação e Configuração

### 1. Clone o repositório

```bash
git clone https://github.com/igorcb/cronos-poc.git
cd cronos-poc
```

### 2. Inicie os containers

```bash
docker-compose up
```

A aplicação estará disponível em: **http://localhost:3000**

### 3. Criar o banco de dados (primeira vez)

```bash
docker-compose run --rm web rails db:create
docker-compose run --rm web rails db:migrate
```

## 🧪 Executando Testes

```bash
# Quando RSpec estiver configurado (Story 1.3)
docker-compose run --rm web bundle exec rspec
```

## 🎨 Compilando Assets

```bash
# JavaScript
docker-compose run --rm web npm run build

# CSS
docker-compose run --rm web npm run build:css
```

## 🔍 Linters e Security

```bash
# RuboCop
docker-compose run --rm web bin/rubocop

# Brakeman (security)
docker-compose run --rm web bin/brakeman

# Bundler Audit (gem vulnerabilities)
docker-compose run --rm web bin/bundler-audit
```

## 📦 Comandos Úteis

```bash
# Parar containers
docker-compose down

# Ver logs
docker-compose logs -f web

# Rails console
docker-compose run --rm web rails console

# Executar migrations
docker-compose run --rm web rails db:migrate

# Criar migration
docker-compose run --rm web rails generate migration NomeDaMigration
```

## 🔄 CI/CD

O projeto usa GitHub Actions para CI. A cada push ou pull request, são executados:

- ✅ **Security Scan** - Brakeman + Bundler Audit
- ✅ **Lint** - RuboCop (Rails Omakase)
- ✅ **Tests** - RSpec (a ser configurado)
- ✅ **Assets** - Build de JavaScript e CSS

## 📝 Licença

Este projeto é um POC (Proof of Concept) para demonstração...
