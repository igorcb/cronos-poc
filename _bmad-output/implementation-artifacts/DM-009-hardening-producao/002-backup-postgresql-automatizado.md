# Story 10.2: Backup PostgreSQL Automatizado (Off-Provider)

**Status:** ready-for-dev
**Domínio:** DM-009-hardening-producao
**Epic:** Epic 10 — Hardening de Produção
**Story ID:** 10.2
**Prioridade:** HIGH
**Estimativa:** 2 SP

---

## Contexto

O PostgreSQL do Cronos POC roda no Railway (managed). O Railway tem snapshots automáticos mas:
1. São **uma camada única** — se a conta Railway for comprometida ou cancelada, dados somem
2. Não há controle sobre retenção (varia por plano)
3. Não há export para arquivo manipulável (pg_dump tradicional)

Esta story configura um **backup automatizado diário para storage externo** (S3 ou Backblaze B2), com dump completo em formato pg_dump (custom format), permitindo restore granular.

---

## História do Usuário

**Como** operador do Cronos POC,
**Quero** ter backups diários do PostgreSQL armazenados fora do Railway,
**Para** poder restaurar dados em caso de falha do provider, corrupção, ou erro humano (DROP TABLE acidental).

---

## Critérios de Aceite

### AC1 — Escolha de storage
- [ ] **AC1.1:** Storage escolhido (S3 / Backblaze B2 / Cloudflare R2)
- [ ] **AC1.2:** Bucket criado com versionamento + retenção 30 dias
- [ ] **AC1.3:** Lifecycle rule: mover para storage frio (Glacier/IA) após 7 dias
- [ ] **AC1.4:** Access key + secret armazenados em `credentials.yml.enc` (não em ENV — uma vez que `master.key` foi rotacionada na 10.1)

### AC2 — Script de backup
- [ ] **AC2.1:** Rake task `db:backup` que executa `pg_dump -Fc` e upload para bucket
- [ ] **AC2.2:** Nomenclatura: `cronos-poc/YYYY-MM-DD/dump-YYYYMMDD-HHMMSS.pgdump`
- [ ] **AC2.3:** Notificação em caso de falha (log estruturado + erro para Sentry/log Railway)
- [ ] **AC2.4:** Backup criptografado (`-Z` + senha extra opcional) ou bucket com SSE-S3 ativo

### AC3 — Agendamento
- [ ] **AC3.1:** Solid Queue cron rodando diariamente às 03:00 UTC (BRT 00:00)
- [ ] **AC3.2:** Job `DbBackupJob` invoca a rake task
- [ ] **AC3.3:** Retry 3x com backoff exponencial se falhar

### AC4 — Restore documentado
- [ ] **AC4.1:** Documentação `RAILWAY_DEPLOY.md` (ou novo `OPERATIONS.md`) com passo-a-passo de restore
- [ ] **AC4.2:** Comando padrão: `pg_restore -d $DATABASE_URL --clean --if-exists dump-YYYYMMDD.pgdump`

### AC5 — Cobertura
- [ ] **AC5.1:** Spec do `DbBackupJob` mockando S3 client → verifica chamada com nome correto
- [ ] **AC5.2:** Spec da rake task `db:backup` rodando contra Postgres de test (faz dump real para `/tmp`, valida tamanho > 0)

### AC6 — Validação manual
- [ ] **AC6.1:** Executar backup manual em produção
- [ ] **AC6.2:** Verificar arquivo no bucket
- [ ] **AC6.3:** Fazer restore em ambiente local com dump da produção (smoke test, sem promover)

---

## Análise Técnica

### Gem sugerida
`aws-sdk-s3` (oficial AWS) ou `fog-aws` (mais abstrato, suporta B2/R2 via compat S3).

### Job

```ruby
class DbBackupJob < ApplicationJob
  queue_as :backups
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform
    timestamp = Time.current.strftime("%Y%m%d-%H%M%S")
    date_dir = Time.current.strftime("%Y-%m-%d")
    key = "cronos-poc/#{date_dir}/dump-#{timestamp}.pgdump"
    tmp = Rails.root.join("tmp/db-backup-#{timestamp}.pgdump")

    pg_dump_to(tmp)
    upload_to_s3(tmp, key)
    File.delete(tmp)

    Rails.logger.info({event: "db_backup_success", key: key, size: tmp_size}.to_json)
  end

  private

  def pg_dump_to(path)
    db = URI.parse(ENV.fetch("DATABASE_URL"))
    cmd = "PGPASSWORD=#{db.password} pg_dump -Fc -h #{db.host} -p #{db.port} -U #{db.user} -d #{db.path[1..]} -f #{path}"
    system(cmd) || raise("pg_dump failed")
  end

  def upload_to_s3(path, key)
    client = Aws::S3::Client.new(
      region: Rails.application.credentials.dig(:s3, :region),
      access_key_id: Rails.application.credentials.dig(:s3, :access_key_id),
      secret_access_key: Rails.application.credentials.dig(:s3, :secret_access_key)
    )
    File.open(path, "rb") do |file|
      client.put_object(bucket: ENV.fetch("BACKUP_BUCKET"), key: key, body: file)
    end
  end
end
```

### Agendamento Solid Queue
```ruby
# config/recurring.yml
production:
  db_backup:
    class: "DbBackupJob"
    queue: backups
    schedule: "0 3 * * *"  # 03:00 UTC daily
```

### Credentials necessárias (criadas via `bin/rails credentials:edit`)
```yaml
s3:
  region: us-east-1
  access_key_id: AKIA...
  secret_access_key: ...
```

### ENV necessárias
- `BACKUP_BUCKET` — nome do bucket
- `DATABASE_URL` — já existe (Railway managed)

---

## Arquivos a Criar/Modificar

| Arquivo | Ação |
|---------|------|
| `Gemfile` | Adicionar `aws-sdk-s3` |
| `app/jobs/db_backup_job.rb` | Criar |
| `lib/tasks/db_backup.rake` | Criar (opcional, se quiser invoke manual) |
| `config/recurring.yml` | Adicionar entrada `db_backup` |
| `config/credentials.yml.enc` | Adicionar credenciais S3 |
| `spec/jobs/db_backup_job_spec.rb` | Criar |
| `RAILWAY_DEPLOY.md` ou `OPERATIONS.md` | Documentar restore |

---

## Testes

- [ ] Spec mockando S3 verifica upload com key correta
- [ ] Spec roda pg_dump real contra DB de test (smoke)
- [ ] Restore manual em ambiente local funcional
- [ ] Backup automático rodou 7 dias consecutivos sem falha

---

## Observações

- **Tamanho esperado:** com base no uso atual single-user, ~5-50 MB por dump. 30 dias = 150-1500 MB total no bucket.
- **Custo S3 standard:** ~$0.023/GB-mês → < $0.05/mês no primeiro ano. Lifecycle para Glacier reduz a centavos.
- **Não usar `pg_dumpall`** — não há motivo de fazer backup de roles/configs, só da base `cronos_poc_production`.
