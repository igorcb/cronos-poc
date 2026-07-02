# Story 10.3: Hook de Verificação de ENVs no Boot da Aplicação

**Status:** ready-for-dev
**Domínio:** DM-009-hardening-producao
**Epic:** Epic 10 — Hardening de Produção
**Story ID:** 10.3
**Prioridade:** MEDIUM
**Estimativa:** 1 SP

---

## Contexto

Hoje o Cronos POC tem **várias ENVs obrigatórias em produção** que, se ausentes, levam a falhas silenciosas ou comportamentos inesperados:

- `RAILS_MASTER_KEY` → falha de decrypt de credentials
- `DATABASE_URL` → falha imediata óbvia
- `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` → botão Google não aparece (graceful degradation existente)
- `ADMIN_EMAIL` / `ADMIN_PASSWORD` → seed do admin usa default `password123` em `db/seeds.rb` (!)
- `INITIAL_TENANT_EMAIL` → migration de backfill falha hard
- `BACKUP_BUCKET` (a partir de 10.2) → backup job falha silenciosamente

Esta story implementa um **initializer que falha o boot do app** se ENVs críticas estiverem ausentes em produção.

---

## História do Usuário

**Como** operador,
**Quero** que o app **se recuse a subir** se faltar ENV crítica em produção,
**Para** detectar configuração incompleta no deploy, não em runtime quando um usuário tropeçar no bug.

---

## Critérios de Aceite

### AC1 — Lista de ENVs obrigatórias
- [ ] **AC1.1:** Criar `config/required_envs.yml` declarando ENVs por ambiente
- [ ] **AC1.2:** Produção: `RAILS_MASTER_KEY`, `DATABASE_URL`, `SECRET_KEY_BASE`, `ADMIN_EMAIL`, `ADMIN_PASSWORD`, `INITIAL_TENANT_EMAIL`
- [ ] **AC1.3:** Produção opcionais (warning, não fatal): `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `BACKUP_BUCKET`, credenciais S3
- [ ] **AC1.4:** Dev/test: sem obrigatórias (Docker e ENVs locais já tem defaults)

### AC2 — Initializer
- [ ] **AC2.1:** `config/initializers/000_validate_envs.rb` (prefixo 000 para rodar antes de tudo)
- [ ] **AC2.2:** Em `Rails.env.production?`, lê yaml e verifica `ENV[key].present?` para cada obrigatória
- [ ] **AC2.3:** Se faltar qualquer obrigatória → `raise` com mensagem clara listando todas as ausentes (não só a primeira)
- [ ] **AC2.4:** Se faltar opcional → `Rails.logger.warn` ao invés de raise

### AC3 — Mensagem de erro
- [ ] **AC3.1:** Formato: "Cronos POC não pode subir em produção sem as seguintes ENVs: RAILS_MASTER_KEY, ADMIN_PASSWORD. Configure no Railway dashboard."
- [ ] **AC3.2:** Stack trace mínima (raise no initializer)

### AC4 — Defaults perigosos removidos
- [ ] **AC4.1:** `db/seeds.rb` linha 9 — remover default `'password123'` de `ENV.fetch('ADMIN_PASSWORD', 'password123')`
- [ ] **AC4.2:** Substituir por `ENV.fetch('ADMIN_PASSWORD')` (sem default) → raise KeyError se ausente
- [ ] **AC4.3:** Em dev/test continua usando default via `.env` (que já existe)

### AC5 — Cobertura
- [ ] **AC5.1:** Spec do initializer (testar em isolamento, stub `Rails.env.production?` e `ENV`)
- [ ] **AC5.2:** Spec: ENV obrigatória ausente → raise
- [ ] **AC5.3:** Spec: ENV opcional ausente → apenas warning no logger
- [ ] **AC5.4:** Spec: todas ENVs presentes → boot OK

### AC6 — Documentação
- [ ] **AC6.1:** `RAILWAY_DEPLOY.md` ou `OPERATIONS.md` documenta as ENVs obrigatórias e onde configurar

---

## Análise Técnica

### Arquivo de declaração

```yaml
# config/required_envs.yml
production:
  required:
    - RAILS_MASTER_KEY
    - DATABASE_URL
    - SECRET_KEY_BASE
    - ADMIN_EMAIL
    - ADMIN_PASSWORD
    - INITIAL_TENANT_EMAIL
  optional:
    - GOOGLE_CLIENT_ID
    - GOOGLE_CLIENT_SECRET
    - BACKUP_BUCKET

development:
  required: []
  optional: []

test:
  required: []
  optional: []
```

### Initializer

```ruby
# config/initializers/000_validate_envs.rb
return unless Rails.env.production?

config = YAML.load_file(Rails.root.join("config/required_envs.yml"))["production"]

missing_required = (config["required"] || []).reject { |k| ENV[k].present? }
missing_optional = (config["optional"] || []).reject { |k| ENV[k].present? }

if missing_required.any?
  raise <<~MSG
    Cronos POC não pode subir em produção sem as seguintes ENVs:
    #{missing_required.join(", ")}

    Configure no Railway dashboard (Variables) e re-deploy.
  MSG
end

missing_optional.each do |k|
  Rails.logger.warn("[boot] ENV opcional ausente: #{k}")
end
```

### Mudança em `db/seeds.rb`

```ruby
# Antes
admin_password = ENV.fetch('ADMIN_PASSWORD', 'password123')

# Depois
admin_password = ENV.fetch('ADMIN_PASSWORD')  # raise KeyError se ausente
```

> Cuidado: rake task `db:seed` em dev precisa de `.env` com `ADMIN_PASSWORD`. Confirmar que `.env.example` lista isso (já lista, conforme a auditoria).

---

## Arquivos a Criar/Modificar

| Arquivo | Ação |
|---------|------|
| `config/required_envs.yml` | Criar |
| `config/initializers/000_validate_envs.rb` | Criar |
| `db/seeds.rb` | Remover default `password123` |
| `RAILWAY_DEPLOY.md` | Atualizar com lista de ENVs |
| `spec/initializers/validate_envs_spec.rb` | Criar |

---

## Testes

- [ ] Initializer com production sem ENV → raise
- [ ] Initializer com production com todas → boot OK
- [ ] Initializer com dev → ignora (não lê yaml)
- [ ] seeds com ADMIN_PASSWORD ausente em dev → KeyError (e dev deve setar via .env)

---

## Observações

- **Por que prefixo `000_`?** Initializers rodam em ordem alfabética. Queremos validação antes de qualquer outro initializer ler ENVs (ex: omniauth.rb lê GOOGLE_CLIENT_ID).
- **Por que não usar `Rails.application.config_for(:required_envs)`?** Mais simples ler yaml direto; config_for adiciona overhead desnecessário para uma lista de strings.
- **Pode ser estendido depois** para validar formato (ex: DATABASE_URL é URL válida, ADMIN_EMAIL casa com regex). Fora de escopo desta story.
