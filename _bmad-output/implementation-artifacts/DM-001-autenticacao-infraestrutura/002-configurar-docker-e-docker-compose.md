# Story 1.2: Configurar Docker e Docker Compose

Status: ready-for-dev

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

- [ ] Criar Dockerfile (AC: #1)
  - [ ] Base image: `ruby:3.4.8-slim`
  - [ ] Instalar dependências do sistema (libpq-dev, nodejs, etc)
  - [ ] Copiar Gemfile e bundle install
  - [ ] Copiar código da aplicação
  - [ ] Expor porta 3000
  - [ ] CMD para iniciar Rails server

- [ ] Criar docker-compose.yml (AC: #2-4)
  - [ ] Service `web`: build from Dockerfile
  - [ ] Service `db`: image `postgres:16-alpine`
  - [ ] Configurar volumes para persistência
  - [ ] Configurar networks para comunicação
  - [ ] Environment variables para database connection

- [ ] Criar .dockerignore
  - [ ] Ignorar node_modules, tmp, log, storage

- [ ] Testar containers (AC: #5-6)
  - [ ] `docker-compose build` compila sem erros
  - [ ] `docker-compose up` inicia services
  - [ ] `docker-compose exec web rails db:create` cria databases
  - [ ] Acessar http://localhost:3000 com sucesso

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
_A ser preenchido pelo Dev Agent_

### Completion Notes List
- [ ] Dockerfile criado com base ruby:3.4.8-slim
- [ ] docker-compose.yml criado com services web e db
- [ ] .dockerignore criado
- [ ] config/database.yml atualizado para usar ENV vars
- [ ] `docker-compose up` funciona sem erros
- [ ] Rails accessible em localhost:3000
- [ ] `docker-compose exec web rails db:create` bem-sucedido

### File List
- Dockerfile
- docker-compose.yml
- .dockerignore
- config/database.yml (modificado)
