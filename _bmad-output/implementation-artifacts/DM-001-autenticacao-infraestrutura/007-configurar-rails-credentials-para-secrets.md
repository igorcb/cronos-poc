# Story 1.7: Configurar Rails Credentials para Secrets

Status: ready-for-dev

## Story

**Como** desenvolvedor,
**Quero** armazenar secrets de forma segura,
**Para que** credenciais não sejam expostas no código.

## Acceptance Criteria

**Given** que autenticação está funcionando

**When** configuro Rails Credentials

**Then**
1. `master.key` está em .gitignore
2. `config/credentials.yml.enc` está versionado (criptografado)
3. `EDITOR="code --wait" rails credentials:edit` abre arquivo descriptografado
4. secret_key_base está presente em credentials
5. Database password pode ser lida de credentials ou ENV
6. config/database.yml usa `Rails.application.credentials.dig(:database, :password)` como fallback

## Tasks / Subtasks

- [ ] Verificar master.key (AC: #1)
  - [ ] Confirmar que master.key existe
  - [ ] Confirmar que master.key está em .gitignore
  - [ ] Fazer backup seguro de master.key

- [ ] Editar credentials (AC: #2-4)
  - [ ] `EDITOR="code --wait" rails credentials:edit`
  - [ ] Adicionar secrets necessários
  - [ ] Salvar e verificar que credentials.yml.enc foi atualizado

- [ ] Configurar database.yml para usar credentials (AC: #5-6)
  - [ ] Modificar config/database.yml
  - [ ] Adicionar fallback: ENV ou credentials

- [ ] Documentar uso de credentials
  - [ ] Atualizar README.md
  - [ ] Criar .env.example atualizado

## Dev Notes

### Rails Credentials

Rails 8 usa **encrypted credentials** por padrão:
- **master.key**: Chave de criptografia (NÃO versionar!)
- **credentials.yml.enc**: Arquivo criptografado (VERSIONADO)

### Verificar .gitignore

```
# config/master.key deve estar em .gitignore
/config/master.key
```

Se não estiver, adicionar!

### Editar Credentials

```bash
# Abrir editor (VS Code)
EDITOR="code --wait" rails credentials:edit

# Ou usar vim
EDITOR="vim" rails credentials:edit

# Ou usar nano
EDITOR="nano" rails credentials:edit
```

### config/credentials.yml.enc (descriptografado)

```yaml
# AWS credentials
aws:
  access_key_id: 123
  secret_access_key: 345

# Database credentials (production)
database:
  password: production_db_password

# Secret key base (gerado automaticamente)
secret_key_base: <long_random_string>

# Outras secrets
api_key: some_api_key
```

### config/database.yml (atualizado)

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  # Fallback: ENV var primeiro, depois credentials
  host: <%= ENV.fetch("DATABASE_HOST", "localhost") %>
  username: <%= ENV.fetch("DATABASE_USER", "postgres") %>
  password: <%= ENV.fetch("DATABASE_PASSWORD") { Rails.application.credentials.dig(:database, :password) } %>

development:
  <<: *default
  database: cronos-poc_development

test:
  <<: *default
  database: cronos-poc_test

production:
  <<: *default
  database: cronos-poc_production
  # Em produção, usar credentials ou ENV
  password: <%= ENV.fetch("DATABASE_PASSWORD") { Rails.application.credentials.dig(:database, :password) } %>
```

### Acessar Credentials no Código

```ruby
# Em qualquer lugar da aplicação Rails
Rails.application.credentials.database[:password]
Rails.application.credentials.aws[:access_key_id]
Rails.application.credentials.api_key

# Com dig (retorna nil se não existir)
Rails.application.credentials.dig(:aws, :access_key_id)
```

### Production Setup

**1. Em servidor de produção, definir RAILS_MASTER_KEY:**

```bash
# Linux/Mac
export RAILS_MASTER_KEY=<conteudo_do_master_key>

# Ou criar config/master.key no servidor com o conteúdo
```

**2. Ou usar credentials específicos de ambiente:**

```bash
# Criar credentials para production
rails credentials:edit --environment production

# Isso cria:
# - config/credentials/production.key (não versionar!)
# - config/credentials/production.yml.enc (versionar!)
```

### Diferença: ENV vars vs Credentials

| Aspecto | ENV vars (.env) | Credentials |
|---------|-----------------|-------------|
| Versionado | ❌ Não (.gitignore) | ✅ Sim (criptografado) |
| Desenvolvimento | ✅ Fácil editar | ❌ Precisa de editor |
| Produção | ✅ Simples (export) | ⚠️ Precisa master.key |
| Segurança | ⚠️ Plain text local | ✅ Criptografado |
| Recomendação | Dev local | Produção + secrets críticos |

### Estratégia Híbrida (Recomendada)

**Development:** Usar .env (fácil, rápido)
```bash
# .env.development
DATABASE_PASSWORD=postgres
ADMIN_PASSWORD=dev123
```

**Production:** Usar credentials (seguro, versionado)
```yaml
# config/credentials.yml.enc
database:
  password: production_secure_password
admin:
  password: production_admin_password
```

**Código:** Fallback para ambos
```ruby
password = ENV.fetch('DATABASE_PASSWORD') {
  Rails.application.credentials.dig(:database, :password)
}
```

### README.md - Documentar

Adicionar ao README:

```markdown
## Secrets Management

### Development
- Copy `.env.example` to `.env.development`
- Edit `.env.development` with your local credentials
- `.env*` files are gitignored for security

### Production
- Use Rails encrypted credentials: `rails credentials:edit`
- Set `RAILS_MASTER_KEY` environment variable on server
- Or copy `config/master.key` to production server (secure channel only!)

### Access Credentials in Code
```ruby
Rails.application.credentials.database[:password]
ENV['DATABASE_PASSWORD']
```
```

### Backup master.key

**CRÍTICO:** Guardar master.key em local seguro!

Opções:
1. **Password Manager** (1Password, LastPass, Bitwarden)
2. **Git privado separado** (não no repo principal!)
3. **Encrypted backup** (GPG, 7zip com senha)

Se perder master.key, perde acesso a todas as credentials!

### Referencias

- [Architecture: Decisão 2.3 - Proteção de Dados Sensíveis](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md#decisão-23-proteção-de-dados-sensíveis)
- [Epics: Story 1.7](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/epics.md#story-17-configurar-rails-credentials-para-secrets)

## Dev Agent Record

### Completion Notes List
- [ ] master.key confirmado em .gitignore
- [ ] rails credentials:edit abre sem erros
- [ ] Secrets adicionados a credentials.yml.enc
- [ ] config/database.yml atualizado com fallback
- [ ] README.md documentado
- [ ] master.key backup realizado (localmente)

### File List
- config/master.key (existe, não versionado)
- config/credentials.yml.enc (modificado, versionado)
- config/database.yml (modificado)
- .gitignore (verificado)
- README.md (modificado)
