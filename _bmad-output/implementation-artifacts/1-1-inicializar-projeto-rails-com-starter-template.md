# Story 1.1: Inicializar Projeto Rails com Starter Template

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

**Como** desenvolvedor,
**Quero** inicializar o projeto Rails 8.1.1 com todas as configurações base,
**Para que** eu tenha um ambiente funcional pronto para desenvolvimento.

## Acceptance Criteria

**Given** que estou iniciando um novo projeto

**When** executo o comando `rails new cronos-poc --database=postgresql --css=tailwind --javascript=esbuild --skip-test`

**Then**
1. Projeto Rails 8.1.1 é criado com Ruby 3.4.8
2. PostgreSQL está configurado como database padrão
3. Tailwind CSS está instalado e configurado
4. esbuild está configurado como bundler JavaScript
5. Hotwire (Turbo + Stimulus) vem instalado por padrão
6. Minitest foi removido (--skip-test)

## Tasks / Subtasks

- [ ] Verificar versões instaladas (AC: #1)
  - [ ] Confirmar Ruby 3.4.8: `ruby -v`
  - [ ] Confirmar Rails 8.1.1: `rails -v`
  - [ ] Confirmar PostgreSQL instalado e rodando

- [ ] Executar comando de inicialização (AC: #1-6)
  - [ ] `rails new cronos-poc --database=postgresql --css=tailwind --javascript=esbuild --skip-test`
  - [ ] Aguardar conclusão do bundle install
  - [ ] Verificar que projeto foi criado em `cronos-poc/`

- [ ] Validar estrutura do projeto (AC: #2-6)
  - [ ] Verificar `config/database.yml` possui configuração PostgreSQL
  - [ ] Verificar `Gemfile` inclui `tailwindcss-rails`
  - [ ] Verificar `package.json` inclui esbuild
  - [ ] Verificar presença de `app/javascript/controllers/` (Stimulus)
  - [ ] Verificar ausência de `test/` directory (Minitest removido)

- [ ] Configurar database inicial
  - [ ] `cd cronos-poc`
  - [ ] `rails db:create` (criar databases development e test)
  - [ ] Verificar criação bem-sucedida

- [ ] Verificar servidor Rails
  - [ ] `bin/dev` ou `rails server` inicia sem erros
  - [ ] Acessar `http://localhost:3000` e ver página inicial Rails
  - [ ] Confirmar Tailwind CSS carregando (inspecionar elementos)

## Dev Notes

### Contexto Arquitetural

**Stack Tecnológico Definido:**
- **Ruby 3.4.8** (stable, lançado em 17/12/2025)
- **Rails 8.1.1** (latest, lançado em 28/10/2025)
- **PostgreSQL** como banco de dados relacional
- **Hotwire** (Turbo + Stimulus) para interatividade frontend
- **Tailwind CSS 4.x** para estilização via `tailwindcss-rails`
- **esbuild** como JavaScript bundler

**Rationale:**
- Rails 8.1 inclui Hotwire nativo, eliminando necessidade de React/Vue
- Tailwind CSS com abordagem utility-first e mobile-first (requisito do projeto)
- esbuild é extremamente rápido para bundling JavaScript
- PostgreSQL é robusto para aggregations (SUM, GROUP BY) necessários nos totalizadores

### Estrutura do Projeto Criada

```
cronos-poc/
├── app/
│   ├── controllers/
│   ├── models/
│   ├── views/
│   │   └── layouts/
│   ├── javascript/
│   │   └── controllers/      # Stimulus controllers
│   ├── assets/
│   │   ├── stylesheets/      # Tailwind config
│   │   └── images/
├── config/
│   ├── database.yml          # PostgreSQL config
│   ├── routes.rb
│   └── tailwind.config.js    # Tailwind config
├── db/
│   └── migrate/
├── Gemfile
├── package.json              # esbuild + npm deps
└── Procfile.dev              # bin/dev processes (Rails + Tailwind)
```

### Comandos Principais

**Desenvolvimento:**
```bash
bin/dev                 # Inicia Rails server + Tailwind watcher
rails server            # Apenas Rails (sem Tailwind watch)
rails console           # Console Rails
```

**Database:**
```bash
rails db:create         # Criar databases
rails db:migrate        # Rodar migrations
rails db:seed           # Rodar seeds
rails db:reset          # Drop, create, migrate, seed
```

### Dependências Automáticas Instaladas

**Gems Instaladas pelo Rails 8.1:**
- `pg` - PostgreSQL adapter
- `turbo-rails` - Turbo Drive, Frames, Streams
- `stimulus-rails` - Stimulus JavaScript framework
- `tailwindcss-rails` - Tailwind CSS integration
- `propshaft` - Asset pipeline (substitui Sprockets)
- `bcrypt` - Password hashing (para autenticação futura)

**npm Packages:**
- `esbuild` - JavaScript bundler
- `@hotwired/turbo-rails` - Turbo frontend
- `@hotwired/stimulus` - Stimulus frontend

### Validações Críticas

**Verificar após criação:**

1. **PostgreSQL Configurado:**
   - Arquivo `config/database.yml` existe
   - Adapter é `postgresql`
   - Database names: `cronos-poc_development`, `cronos-poc_test`

2. **Tailwind CSS Funcional:**
   - `app/assets/stylesheets/application.tailwind.css` existe
   - `config/tailwind.config.js` existe
   - Procfile.dev inclui processo `css: bin/rails tailwindcss:watch`

3. **Hotwire Instalado:**
   - `Gemfile` inclui `turbo-rails` e `stimulus-rails`
   - `app/javascript/application.js` importa Turbo e Stimulus
   - Diretório `app/javascript/controllers/` existe

4. **Minitest Ausente:**
   - Diretório `test/` NÃO existe
   - `Gemfile` NÃO inclui minitest

### Próximas Stories (Contexto)

**Story 1.2:** Configurar Docker + Docker Compose
- Dockerfile com base `ruby:3.4.8-slim`
- docker-compose.yml com services `web` (Rails) e `db` (PostgreSQL 16)

**Story 1.3:** Configurar RSpec + FactoryBot
- Substituir Minitest por RSpec
- Adicionar gems de teste: `rspec-rails`, `factory_bot_rails`, `faker`, `shoulda-matchers`

**Story 1.4:** Configurar Code Quality Tools
- Rubocop, Bullet, Annotate

### Troubleshooting

**Problema:** `rails db:create` falha com erro PostgreSQL connection
**Solução:**
1. Verificar PostgreSQL está rodando: `pg_isready`
2. Se não, iniciar: `sudo service postgresql start` (Linux) ou `brew services start postgresql` (macOS)
3. Verificar credenciais em `config/database.yml`

**Problema:** Tailwind não compila CSS
**Solução:**
1. Usar `bin/dev` ao invés de `rails server` (inclui Tailwind watcher)
2. Ou rodar manualmente: `rails tailwindcss:watch` em terminal separado

**Problema:** esbuild não encontrado
**Solução:**
1. Verificar Node.js instalado: `node -v` (precisa v18+)
2. Reinstalar dependências: `npm install`

### Project Context Notes

**Alinhamento com Estrutura Unificada:**
- Esta é a primeira story, estabelecendo a estrutura base
- Convenções Rails padrão serão seguidas
- Naming conventions: snake_case para tabelas/colunas, PascalCase para classes

**Futuras Adições:**
- `app/components/` - ViewComponents (Story futura)
- `app/services/` - Service Objects para lógica complexa
- `spec/` - Testes RSpec (Story 1.3)

### References

- [Architecture: Avaliação de Starter Template](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md#avaliação-de-starter-template)
- [Architecture: Comando de Inicialização](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md#comando-de-inicialização-do-projeto)
- [Architecture: Stack Tecnológico](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md#stack-tecnológico-definido)
- [Epics: Story 1.1](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/epics.md#story-11-inicializar-projeto-rails-com-starter-template)

## Dev Agent Record

### Agent Model Used

_A ser preenchido pelo Dev Agent durante execução_

### Debug Log References

_A ser preenchido pelo Dev Agent se houver problemas_

### Completion Notes List

_A ser preenchido pelo Dev Agent ao finalizar:_
- [ ] Comando rails new executado com sucesso
- [ ] Databases criadas (development, test)
- [ ] Servidor Rails inicia sem erros
- [ ] Tailwind CSS carregando corretamente
- [ ] Hotwire (Turbo + Stimulus) funcional
- [ ] Estrutura de projeto validada

### File List

_A ser preenchido pelo Dev Agent com arquivos criados/modificados_

---

## CRITICAL DEVELOPER GUARDRAILS

### ⚠️ VALIDAÇÕES OBRIGATÓRIAS

1. **ANTES de marcar story como concluída, VERIFICAR:**
   - [ ] `rails -v` retorna exatamente "Rails 8.1.1"
   - [ ] `ruby -v` retorna Ruby 3.4.8
   - [ ] `rails db:create` executa sem erros
   - [ ] `bin/dev` inicia Rails + Tailwind watcher
   - [ ] Página `http://localhost:3000` carrega
   - [ ] Inspetor de elementos mostra classes Tailwind aplicadas

2. **NÃO PROSSEGUIR para Story 1.2 se:**
   - PostgreSQL não estiver configurado corretamente
   - Tailwind CSS não estiver compilando
   - Hotwire não estiver instalado
   - Existir diretório `test/` (Minitest não foi removido)

### 🎯 OBJETIVOS DESTA STORY

**Esta story APENAS inicializa o projeto. NÃO implemente:**
- ❌ Models, migrations, controllers (vêm em stories futuras)
- ❌ Docker/Docker Compose (Story 1.2)
- ❌ RSpec/Testes (Story 1.3)
- ❌ Rubocop/Code Quality (Story 1.4)
- ❌ Autenticação (Story 1.5)

**Esta story DEVE entregar:**
- ✅ Projeto Rails 8.1.1 funcional
- ✅ PostgreSQL configurado
- ✅ Tailwind CSS compilando
- ✅ Hotwire instalado
- ✅ Servidor Rails rodando

### 📝 NOTAS DE IMPLEMENTAÇÃO

**Versões Críticas:**
- Ruby: **3.4.8** (NÃO usar 4.0.0, muito recente)
- Rails: **8.1.1** (versão com todas as features Hotwire modernas)
- PostgreSQL: Qualquer versão 13+ (recomendado 16)

**Comando Exato:**
```bash
rails new cronos-poc \
  --database=postgresql \
  --css=tailwind \
  --javascript=esbuild \
  --skip-test
```

**IMPORTANTE:** Use EXATAMENTE este comando. Flags adicionais podem causar conflitos.
