---
workflowType: 'architecture'
workflow: 'final'
project_name: 'cronos-poc'
user_name: 'Igor'
date: '2026-05-26'
status: 'shipped'
inputDocuments: ['prd.md']
---

# Architecture — Cronos POC

**Status:** Final (refletindo o sistema em produção em 2026-05-26)

---

## 1. Visão geral

Aplicação **Rails 8 monolito** com frontend Hotwire (Turbo + Stimulus + Tailwind), banco PostgreSQL, autenticação dupla (email/senha + Google OAuth) e isolamento multi-tenant por `user_id`. Deploy em Railway via push automático no merge da master. Sem React, sem API separada, sem microsserviços — Hotwire serve toda a UI com Turbo Streams para atualizações em tempo real.

---

## 2. Stack técnica

| Camada | Tecnologia | Versão |
|--------|-----------|--------|
| **Linguagem** | Ruby | 3.4.8 |
| **Framework** | Rails | 8.1.x |
| **Banco** | PostgreSQL | 16 (Railway gerenciado) |
| **Frontend** | Hotwire (Turbo + Stimulus) + Tailwind CSS v4 | — |
| **Asset pipeline** | Propshaft + jsbundling-rails + cssbundling-rails | — |
| **Background jobs** | Solid Queue (in-process com Puma) | — |
| **Action Cable** | Solid Cable (DB-backed pub/sub) | — |
| **Cache** | Solid Cache | — |
| **Autenticação** | `has_secure_password` (email/senha) + omniauth-google-oauth2 (Google OAuth) | — |
| **Servidor** | Puma + Thruster (HTTP/2, caching, X-Sendfile) | — |
| **Containerização** | Docker (Dockerfile multi-stage) | — |
| **Deploy** | Railway (push-to-deploy via GitHub) | — |
| **Testes** | RSpec + FactoryBot + Faker + Capybara + Selenium | — |
| **Cobertura** | SimpleCov (100% line, enforced no CI) | — |
| **CI** | GitHub Actions (lint, security scan, assets, tests) | — |

---

## 3. Modelo de domínio

```
User (1) ──── (N) Company ──── (N) Project ──── (N) Task ──── (N) TaskItem
  │                                                  │
  └──────── has_many sessions, has_one onboarding_state (computed)
                                                     │
                                            status: pending|completed|delivered
                                            snapshots: hourly_rate, delivered_value
```

### Entidades principais

| Modelo | Colunas-chave | Notas |
|--------|---------------|-------|
| **User** | email, password_digest (opcional), google_uid, name, avatar_url | Suporta auth dupla; OAuth pode coexistir com senha |
| **Session** | user_id, token, ip_address, user_agent | Cookie signed[:session_id] |
| **Company** | name, hourly_rate, active, **user_id** | Soft delete via `active: false` |
| **Project** | name, company_id, **user_id** | Valida que company pertence ao user (cascata) |
| **Task** | code, name, estimated_hours, validated_hours, status, start_date, end_date, delivery_date, hourly_rate (snapshot), delivered_value (snapshot), notes, company_id, project_id, **user_id** | Status automático por callback |
| **TaskItem** | start_time, end_time, work_date, hours_worked (calc), hourly_rate (snapshot), value (snapshot), task_id, **user_id** | Callback before_save calcula hours_worked e value |
| **IdlePeriod** *(Epic 13 / DM-012)* | start_time, end_time, hours (calc), **user_id** | Registro manual de disponibilidade sem tarefa; não vinculado a Company/Project/Task; **não soma** no total de horas trabalhadas |
| **Current** | `CurrentAttributes` com `user`, `session` | Multi-tenant context global por request |
| **OnboardingState** | PORO derivado de counts | step_1/step_2/step_3/completed |

### Multi-tenancy — Defense in depth

```ruby
# 1. Concern de scoping em controllers
module TenantScoped
  def scoped_companies; current_user.companies; end
  def scoped_tasks; current_user.tasks; end
  # ...
end

# 2. Custom validator nos models
validates :company_id, belongs_to_current_user: { class_name: 'Company' }

# 3. Turbo Stream com signed stream por user
turbo_stream_from [current_user, :dashboard]

# 4. Strong params NUNCA permitem user_id
def task_params
  params.require(:task).permit(:name, :code, ...) # sem :user_id
end
```

Acesso cross-tenant retorna **404** (não 403) — não vaza existência de IDs.

---

## 4. Arquitetura de controllers

| Controller | Endpoints |
|------------|-----------|
| **SessionsController** | new, create, destroy (login email/senha) |
| **OmniauthCallbacksController** | google_oauth2 (callback OAuth) |
| **PasswordsController** | new, create, edit, update (reset por email) |
| **DashboardController** | index (com onboarding ou normal) |
| **CompaniesController** | index, new, create, edit, update, destroy |
| **ProjectsController** | index, new, create, edit, update, destroy |
| **TasksController** | index, new, create, edit, update, destroy, deliver, reopen, reopen_modal |
| **TaskItemsController** | new (modal), create, update, destroy (todos turbo_stream) |
| **DailySummaryController** | index (com filtro de mês) |
| **IdlePeriodsController** *(Epic 13 / DM-012)* | new (modal), create, destroy (turbo_stream) — mesmo padrão de `TaskItemsController` |
| **ProfilesController** | show, edit, update (alteração de senha) |
| **DashboardEventsController** | events (SSE legacy, filtrado de coverage) |
| **DashboardBroadcastJob** | Job que dispara broadcast pelo stream assinado por user |

Todos herdam `ApplicationController` que inclui `Authentication` (require_authentication + Current.session/user lifecycle).

---

## 5. Padrões de frontend

### Hotwire stack
- **Turbo Drive** — navegação sem reload por padrão
- **Turbo Frames** — modais (`#modal`), formulários inline
- **Turbo Streams** — KPIs do dashboard, lista de tasks, histórico de TaskItems
- **Stimulus controllers** — `modal`, `tabs`, `project_selector`, `form_validation`, `task_item_hours`, `task_item_edit`, `navbar`, `filter`

### Tailwind v4
- Custom utility classes via arbitrary values (`max-w-[1536px]`)
- Sem PostCSS plugins; CLI puro do `@tailwindcss/cli`
- Build via `npm run build:css`

### Padrão de modais
```erb
<turbo-frame id="modal">
  <div role="dialog" aria-modal="true" data-controller="modal"
       data-action="keydown.escape@window->modal#close click->modal#closeOnOverlayClick">
    ...
  </div>
</turbo-frame>
```

### Padrão Turbo Stream broadcasts
- `DashboardBroadcastJob.perform_later(current_user.id)` após mudanças em Tasks/TaskItems
- Stream **assinado por user**: `[user, :dashboard]` — evita previsibilidade e leak entre tenants
- `Current.user` resetado em `ensure` para não vazar entre jobs do SolidQueue

---

## 6. Decisões arquiteturais registradas (ADR-style)

| # | Decisão | Por quê |
|---|---------|---------|
| DA-001 | Auth com `has_secure_password` (sem Devise) | Rails 8 stack moderna, menos magia |
| DA-002 | SimpleCov 100% enforced no CI | Detecta CI falsamente verde, força disciplina |
| DA-003 | Multi-tenancy via `user_id` direto + `Current.user` | Mais simples que acts_as_tenant; defense in depth |
| DA-004 | OAuth coexiste com email/senha | Permite migração gradual; admin legacy não quebra |
| DA-005 | Snapshots imutáveis de `hourly_rate`/`value` | Auditoria financeira: rate da empresa pode mudar, snapshot preserva |
| DA-035 | Modal de exclusão de TaskItem com confirm + recalc validated_hours | Story 5.18 |
| DA-042 | Turbo Stream HTTP > ActionCable para TaskItem | Estabilidade + simplicidade |
| DA-099 | OnboardingState como PORO derivado | Sem coluna no User; counts são fonte da verdade |
| DA-100 | `IdlePeriod` como model separado de Task/TaskItem (Epic 13 / DM-012) | Evita contaminar lógica de status/snapshot/delivered de Task; horas não somam no total trabalhado por design |
| DA-101 | KPI de horas "Sem Tarefa" calculado no `DashboardController`, broadcast via `DashboardBroadcastJob` existente | Reaproveita pipeline de Turbo Stream por user já validado; sem novo canal |
| DA-102 | Sem validação de overlap entre `IdlePeriod` e `Task`/`TaskItem` no MVP | Simplicidade; reavaliar se uso real revelar necessidade |

---

## 7. Estratégia de testes

| Tipo | Quantidade | Cobertura |
|------|------------|-----------|
| Model specs | ~200 | 100% |
| Request specs | ~600 | 100% |
| Controller specs | ~150 | 100% |
| View/Component specs | ~80 | 100% |
| Job/Channel specs | ~30 | 100% |
| Validator specs | ~20 | 100% |
| System specs (Capybara) | ~40 | parcial |
| **Total** | **1.120** | **100% line** |

### Heurísticas firmadas (via 72 QA findings)
- Não asserir `include("X")` em string curta — usar regex com contexto
- Validar `I18n.t(...).is_a?(Array)` antes de indexar
- `pluck + sum` em Ruby > `distinct.sum` em SQL multi-tabela
- Specs de view multi-tenancy verificam isolamento real
- Playwright a partir do Dashboard simula usuário real

---

## 8. CI/CD

```yaml
# .github/workflows/ci.yml — jobs em paralelo
security:
  - bin/bundler-audit --update
  - bin/brakeman -q -w2

lint:
  - bin/rubocop --parallel

tests:
  - bin/rails db:prepare
  - bundle exec rspec  # 1.120 examples, 100% line coverage enforced

assets:
  - npm run build
  - npm run build:css
```

CI falha o merge se:
- Cobertura < 100%
- Specs falham
- Brakeman/bundler-audit reportam vulnerabilidade
- RuboCop falha
- Branch out-of-date com main

---

## 9. Deploy

### Pipeline Railway
1. Push para `master` no GitHub
2. Railway detecta via webhook
3. Builda Docker image
4. Aplica migrations
5. Substitui container Web em rolling deploy
6. Healthcheck via `/up` (Rails padrão)

### ENV vars necessárias em produção
- `RAILS_MASTER_KEY` — para decrypt de `credentials.yml.enc`
- `DATABASE_URL` — gerenciado pelo Railway (PostgreSQL service)
- `RAILS_ENV=production`
- `SECRET_KEY_BASE`
- `GOOGLE_CLIENT_ID` + `GOOGLE_CLIENT_SECRET` (para OAuth)
- `INITIAL_TENANT_EMAIL` (backfill multi-tenancy da migration)
- `ADMIN_EMAIL` + `ADMIN_PASSWORD` (seed do admin user)

### Arquivos de deploy
- `Dockerfile` — multi-stage build oficial Rails 8
- `.railway.json` — config Railway
- `RAILWAY_DEPLOY.md` — documentação operacional
- `scripts/deploy-railway.sh` — script de deploy manual
- `Procfile` — comando web (Puma + Thruster)

**Não usados (código morto):**
- `config/deploy.yml` (Kamal — placeholders padrão)
- `.kamal/secrets` (template, sem segredos reais)

---

## 10. Observabilidade atual

- Logs da aplicação retidos pelo Railway (janela limitada)
- Sem APM (New Relic, Datadog, Skylight)
- Sem error tracking dedicado (Sentry, Honeybadger)
- Sem analytics de produto (Plausible, PostHog)

**Roadmap sugerido em Epic 11.**

---

## 11. Segurança

| Item | Status |
|------|--------|
| HTTPS em produção | ✅ Railway TLS |
| CSRF | ✅ Rails padrão + `omniauth-rails_csrf_protection` |
| SQL injection | ✅ ActiveRecord parameterizado |
| XSS | ✅ ERB escape por padrão |
| Strong params | ✅ Em todos os controllers |
| `master.key` | 🔴 **Vazada no histórico** — exige rotação |
| Brakeman | ✅ Roda no CI |
| Bundler audit | ✅ Roda no CI |
| Multi-tenancy 404 cross-tenant | ✅ Validado |
| Session cookie httponly + signed | ✅ |
| Password storage | ✅ bcrypt via has_secure_password |
| Rate limiting (passwords#create) | ✅ Rails 8 built-in (10/3min) |

---

## 12. Performance

- **Cobertura sem N+1** validada em request specs (limite de queries em endpoints críticos)
- Eager loading explícito em `DashboardController` e `TasksController#index`
- Turbo Drive evita full page reload
- Solid Cache reduz hits ao DB em assets/fragmentos
- Solid Queue roda in-process (não exige Sidekiq/Redis)

Sem benchmarks formais — performance perceptual aceitável em produção single-user.
