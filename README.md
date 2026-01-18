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

## 🔐 Secrets e Credentials

### Desenvolvimento Local

1. Copie `.env.example` para `.env.development`:
   ```bash
   cp .env.example .env.development
   ```

2. Edite `.env.development` com suas credenciais locais

### Produção (Railway)

O projeto usa **Rails Encrypted Credentials** para secrets em produção:

- `config/credentials.yml.enc` - Arquivo criptografado (versionado)
- `config/master.key` - Chave de descriptografia (NÃO versionado)

**Configuração no Railway:**
1. Acesse o dashboard do Railway
2. Adicione a variável de ambiente:
   - `RAILS_MASTER_KEY` = conteúdo do arquivo `config/master.key`

**Editar credentials localmente:**
```bash
EDITOR="code --wait" bin/rails credentials:edit
```

**Visualizar credentials:**
```bash
bin/rails credentials:show
```

**Acessar no código:**
```ruby
Rails.application.credentials.secret_key_base
Rails.application.credentials.dig(:aws, :access_key_id)
```

### Backup da Master Key

A `master.key` é crítica - sem ela, não há acesso às credentials. Mantenha backup seguro em:
- Password Manager (1Password, Bitwarden)
- Arquivo criptografado separado

## 🔄 CI/CD

O projeto usa GitHub Actions para CI. A cada push ou pull request, são executados:

- ✅ **Security Scan** - Brakeman + Bundler Audit
- ✅ **Lint** - RuboCop (Rails Omakase)
- ✅ **Tests** - RSpec (a ser configurado)
- ✅ **Assets** - Build de JavaScript e CSS

## 📝 Licença

Este projeto é um POC (Proof of Concept) para demonstração...
