# Story 11.2: Healthcheck Endpoint `/up` Customizado

**Status:** ready-for-dev
**Domínio:** DM-010-observabilidade-ux-polish
**Epic:** Epic 11 — Observabilidade & UX Polish
**Story ID:** 11.2
**Prioridade:** MEDIUM
**Estimativa:** 1 SP

---

## Contexto

Rails 8 já vem com um endpoint `/up` padrão (`Rails::HealthController#show`) que retorna 200 se o Rails carregou. **Não verifica DB nem jobs.**

O Railway usa esse endpoint para healthcheck de deploy. Se o DB cair mas o Puma estiver vivo, o Railway considera saudável → roteia tráfego para um app quebrado.

Esta story substitui por um healthcheck que verifica:
- DB acessível (`ActiveRecord::Base.connection.execute("SELECT 1")`)
- Solid Queue não está com fila enorme acumulada
- ENVs críticas presentes (reforço da 10.3, mas em runtime)

---

## História do Usuário

**Como** operador,
**Quero** que `/up` retorne 503 se DB ou jobs estiverem com problema,
**Para** que Railway/load balancer pare de rotear tráfego para containers degradados.

---

## Critérios de Aceite

### AC1 — Endpoint customizado
- [ ] **AC1.1:** Rota `/up` mapeia para `HealthController#show` customizado (substituir o padrão Rails)
- [ ] **AC1.2:** Pula `before_action :require_authentication` (público)
- [ ] **AC1.3:** Sem layout, sem assets, apenas JSON

### AC2 — Checks executados
- [ ] **AC2.1:** **DB:** `ActiveRecord::Base.connection.execute("SELECT 1").any?` → boolean
- [ ] **AC2.2:** **Solid Queue:** `SolidQueue::Job.where(finished_at: nil).count < threshold` (configurável, ex: 1000)
- [ ] **AC2.3:** **Cache:** `Rails.cache.read("__healthcheck__").nil?` ou pelo menos `Rails.cache.write` + leitura sem raise
- [ ] **AC2.4:** **Migrations pendentes:** `ActiveRecord::Migration.check_pending!` → captura erro

### AC3 — Response
- [ ] **AC3.1:** Sucesso: `200 OK` + JSON `{"status": "ok", "checks": {"db": true, "queue": true, "cache": true, "migrations": true}, "timestamp": "..."}`
- [ ] **AC3.2:** Falha: `503 Service Unavailable` + JSON com `false` no check que falhou
- [ ] **AC3.3:** Timeout interno: cada check tem timeout de 2s; se exceder, vira `false`

### AC4 — Performance
- [ ] **AC4.1:** Cache da resposta por 5 segundos para evitar flood (Railway probe a cada 10s)
- [ ] **AC4.2:** Sem N+1 (`SolidQueue::Job.count` é OK pois é COUNT direto)

### AC5 — Cobertura
- [ ] **AC5.1:** Spec: todos checks OK → 200 + JSON correto
- [ ] **AC5.2:** Spec: DB down (stub `connection.execute` raise) → 503
- [ ] **AC5.3:** Spec: queue acima do threshold → 503

### AC6 — Configuração Railway
- [ ] **AC6.1:** Verificar/atualizar `RAILWAY_DEPLOY.md` mencionando `/up` como healthcheck path
- [ ] **AC6.2:** No `.railway.json` ou dashboard, confirmar `healthcheckPath: "/up"`

---

## Análise Técnica

### Controller

```ruby
class HealthController < ApplicationController
  skip_before_action :require_authentication, raise: false

  CACHE_KEY = "healthcheck:result".freeze
  CACHE_TTL = 5.seconds
  QUEUE_THRESHOLD = 1000

  def show
    result = Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) { run_checks }

    status = result[:checks].values.all? ? :ok : :service_unavailable
    render json: result, status: status
  end

  private

  def run_checks
    {
      status: nil,  # preenche depois
      timestamp: Time.current.iso8601,
      checks: {
        db: check_db,
        queue: check_queue,
        cache: check_cache,
        migrations: check_migrations
      }
    }.tap { |r| r[:status] = r[:checks].values.all? ? "ok" : "degraded" }
  end

  def check_db
    Timeout.timeout(2) { ActiveRecord::Base.connection.execute("SELECT 1").any? }
  rescue StandardError
    false
  end

  def check_queue
    Timeout.timeout(2) { SolidQueue::Job.where(finished_at: nil).count < QUEUE_THRESHOLD }
  rescue StandardError
    false
  end

  def check_cache
    Timeout.timeout(2) { Rails.cache.write("__hc__", true) && Rails.cache.read("__hc__") }
  rescue StandardError
    false
  end

  def check_migrations
    ActiveRecord::Migration.check_pending!
    true
  rescue StandardError
    false
  end
end
```

### Rota

```ruby
# config/routes.rb
get "/up", to: "health#show"
# Remove qualquer outra entrada que aponte para Rails::HealthController
```

---

## Arquivos a Criar/Modificar

| Arquivo | Ação |
|---------|------|
| `app/controllers/health_controller.rb` | Criar |
| `config/routes.rb` | Substituir `/up` padrão por nosso |
| `spec/requests/health_spec.rb` | Criar |
| `RAILWAY_DEPLOY.md` | Documentar healthcheck path |

---

## Testes

- [ ] GET /up com tudo OK → 200 + JSON
- [ ] DB down → 503 + db: false no payload
- [ ] Cache do resultado por 5s funciona

---

## Observações

- **Por que não usar a gem `health_check`?** Adiciona 1 dep para algo simples. Controller customizado é mais explícito.
- **Threshold do queue (1000) é palpite inicial** — ajustar com base no uso real. Em SaaS single-user ainda, qualquer fila com 100+ jobs já é sinal de problema.
- **Próximo passo opcional:** expor métricas Prometheus em `/metrics` se algum dia migrar para infra com Prometheus.
