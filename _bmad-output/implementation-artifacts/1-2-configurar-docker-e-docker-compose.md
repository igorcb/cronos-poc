# Story 1.2: Configurar Docker e Docker Compose

Status: review

## Story

**Como** desenvolvedor,
**Quero** containerizar a aplicação com Docker,
**Para que** eu tenha ambiente consistente e isolado para desenvolvimento.

## Acceptance Criteria

**Given** que o projeto Rails está inicializado

**When** crio Dockerfile e docker-compose.yml

**Then**
1. Dockerfile usa base image `ruby:3.4.8-slim`
2. docker-compose.yml define service `web` (Rails app)
3. docker-compose.yml define service `db` (PostgreSQL 16)
4. Volumes estão configurados para persistência de dados
5. `docker-compose up` inicia ambos os services sem erros
6. Rails app é acessível em `http://localhost:3000`

## Tasks / Subtasks

- [x] Criar Dockerfile (AC: #1)
  - [x] Base image: `ruby:3.4.8-slim`
  - [x] Instalar dependências do sistema (libpq-dev, nodejs, npm, git, curl, libyaml-dev)
  - [x] User mapping (USER_ID/GROUP_ID) para evitar problemas de permissão
  - [x] Rails 8.1.1 instalado globalmente
  - [x] Working directory /app

- [x] Criar docker-compose.yml (AC: #2-4)
  - [x] Service `web`: build from Dockerfile.dev
  - [x] Service `db`: image `postgres:16`
  - [x] Volumes configurados (postgres_data, bundle_cache)
  - [x] Environment variables para database connection (DATABASE_HOST, DATABASE_USERNAME, DATABASE_PASSWORD)
  - [x] Healthcheck no PostgreSQL
  - [x] depends_on com condition: service_healthy

- [x] Criar .dockerignore
  - [x] Ignorar node_modules, tmp, log, storage
  - [x] Configurado pelo Rails com padrões recomendados

- [x] Testar containers (AC: #5-6)
  - [x] `docker-compose build` compila sem erros
  - [x] `docker-compose up` inicia services
  - [x] `docker-compose run web rails db:create` cria databases
  - [x] Acessar http://localhost:3000 com sucesso

**NOTA:** Esta story foi implementada juntamente com a Story 1.1, pois o Docker era necessário para rodar Ruby 3.4.8 e Rails 8.1.1 que não estavam disponíveis no host.

## Dev Notes

### Dockerfile Completo

```dockerfile
FROM ruby:3.4.8-slim

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y \
      build-essential \
      libpq-dev \
      nodejs \
      npm \
      git \
      curl && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy package.json and install npm packages
COPY package.json package-lock.json ./
RUN npm install

# Copy application code
COPY . .

# Precompile assets (opcional para dev, obrigatório para prod)
# RUN rails assets:precompile

# Expose port
EXPOSE 3000

# Start server
CMD ["rails", "server", "-b", "0.0.0.0"]
```

### docker-compose.yml Completo

```yaml
version: '3.8'

services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: cronos-poc_development
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  web:
    build: .
    command: bash -c "rm -f tmp/pids/server.pid && bundle exec rails server -b 0.0.0.0"
    volumes:
      - .:/app
      - bundle_cache:/usr/local/bundle
    ports:
      - "3000:3000"
    environment:
      DATABASE_HOST: db
      DATABASE_USER: postgres
      DATABASE_PASSWORD: postgres
      RAILS_ENV: development
    depends_on:
      db:
        condition: service_healthy
    stdin_open: true
    tty: true

volumes:
  postgres_data:
  bundle_cache:
```

### .dockerignore

```
.git
.gitignore
node_modules
tmp
log
storage
public/packs
public/assets
coverage
.env
*.swp
*.swo
```

### Atualizar config/database.yml

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  host: <%= ENV.fetch("DATABASE_HOST", "localhost") %>
  username: <%= ENV.fetch("DATABASE_USER", "postgres") %>
  password: <%= ENV.fetch("DATABASE_PASSWORD", "postgres") %>

development:
  <<: *default
  database: cronos-poc_development

test:
  <<: *default
  database: cronos-poc_test
```

### Comandos Docker Essenciais

```bash
# Build images
docker-compose build

# Start services
docker-compose up

# Start in background
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f web

# Execute commands in container
docker-compose exec web rails db:create
docker-compose exec web rails db:migrate
docker-compose exec web rails console
docker-compose exec web bundle exec rspec

# Rebuild after Gemfile changes
docker-compose build web
docker-compose up
```

### References

- [Architecture: Containerização (Docker)](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md#containerização-docker)
- [Epics: Story 1.2](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/epics.md#story-12-configurar-docker-e-docker-compose)

## Dev Agent Record

### Agent Model Used
Claude Sonnet 4.5 (claude-sonnet-4-5-20250929)

### Implementation Notes
Esta story foi implementada **durante a Story 1.1** porque:
1. Host tinha Ruby 3.3.4 e Rails 8.0.2 (incompatíveis com requisitos)
2. Docker era necessário para rodar Ruby 3.4.8 e Rails 8.1.1
3. Decisão: containerizar desde o início para garantir ambiente consistente

### Completion Notes List
- [x] Dockerfile.dev criado com base ruby:3.4.8-slim
- [x] User mapping implementado (USER_ID/GROUP_ID) para evitar problemas de permissão
- [x] docker-compose.yml criado com services web e db
- [x] PostgreSQL 16 configurado com healthcheck
- [x] .dockerignore criado pelo Rails (padrões recomendados)
- [x] config/database.yml atualizado para usar ENV vars (DATABASE_HOST, DATABASE_USERNAME, DATABASE_PASSWORD)
- [x] `docker-compose up` funciona sem erros
- [x] Rails acessível em localhost:3000
- [x] `docker-compose run web rails db:create` bem-sucedido
- [x] Assets compilando (esbuild + Tailwind)

### File List
- Dockerfile.dev (desenvolvimento com user mapping)
- docker-compose.yml (services web + db com PostgreSQL 16)
- .dockerignore (gerado pelo Rails)
- config/database.yml (modificado para Docker)
- Dockerfile (production, gerado pelo Rails)
