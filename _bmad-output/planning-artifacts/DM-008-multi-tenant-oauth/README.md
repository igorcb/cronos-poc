# DM-008 — Multi-Tenancy & Google OAuth

**Tipo:** Transversal / Segurança & SaaS
**Epic associado:** 9
**Stories:** 3
**Status:** ✅ done (entregue 2026-05-26)

---

## Propósito

Transformar o Cronos POC de **single-user MVP** em **SaaS multi-tenant real**, permitindo:
1. Cadastro self-service via Google OAuth (alternativa ao email/senha)
2. Isolamento total de dados entre usuários (Companies/Projects/Tasks/TaskItems)
3. Onboarding guiado para novos usuários

---

## Stories

| # | Título | Status |
|---|--------|--------|
| 9.1 | Login via Google OAuth (lado a lado com email/senha) | ✅ done |
| 9.2 | Multi-tenancy — isolamento por usuário | ✅ done |
| 9.3 | Onboarding — primeiro acesso (3 passos) | ✅ done |

---

## Arquitetura entregue

### Auth dual
```ruby
class User < ApplicationRecord
  has_secure_password validations: false  # opcional
  validates :password, length: { minimum: 6 }, if: -> { password.present? }
  validates :google_uid, uniqueness: true, allow_nil: true

  def self.from_google_omniauth(auth)
    user = find_by(google_uid: auth.uid) || find_or_initialize_by(email: auth.info.email)
    user.assign_attributes(google_uid: auth.uid, email: auth.info.email,
                            name: auth.info.name, avatar_url: auth.info.image)
    user.save!
    user
  end
end
```

### Multi-tenancy defense-in-depth

**Camada 1 — Concern TenantScoped nos controllers:**
```ruby
module TenantScoped
  def scoped_companies; current_user.companies; end
  def scoped_tasks; current_user.tasks; end
  def scoped_task_items; current_user.task_items; end
end
```

**Camada 2 — Custom validator nos models:**
```ruby
class BelongsToCurrentUserValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless Current.user
    klass = options[:class_name].constantize
    unless klass.where(id: value, user_id: Current.user.id).exists?
      record.errors.add(attribute, :not_yours)
    end
  end
end
```

**Camada 3 — Turbo Stream assinado por user:**
```erb
<%= turbo_stream_from [current_user, :dashboard] %>
```

**Camada 4 — Job lifecycle:**
```ruby
class DashboardBroadcastJob < ApplicationJob
  def perform(user_id)
    user = User.find_by(id: user_id)
    Current.set(user: user) do
      Turbo::StreamsChannel.broadcast_render_to([user, :dashboard], ...)
    end
  ensure
    Current.reset  # crítico para SolidQueue thread pollution
  end
end
```

### Onboarding sem persistência
```ruby
class OnboardingState
  def initialize(user)
    @user = user
  end

  def step
    return :completed if @user.tasks.exists?
    return :step_3 if @user.projects.exists?
    return :step_2 if @user.companies.exists?
    :step_1
  end

  def active?
    step != :completed
  end
end
```

Estado derivado de counts — sem coluna no User. Se user deletar todas as companies, onboarding volta.

---

## Migrations entregues

### Story 9.1
- `add_google_oauth_to_users.rb` — `google_uid` (string, unique, indexed), `name`, `avatar_url`

### Story 9.2
- `add_user_to_tenant_tables.rb` — `user_id` (bigint, null: true, foreign_key) em companies, projects, tasks, task_items
- `backfill_user_id_in_tenant_tables.rb` — `update_all(user_id: initial_user.id)` via `ENV["INITIAL_TENANT_EMAIL"]`
- `enforce_user_id_not_null.rb` — `change_column_null :tabela, :user_id, false`

---

## Riscos & mitigações aplicados

| Risco | Mitigação |
|-------|-----------|
| Backfill em prod sem user inicial | Migration falha hard se `INITIAL_TENANT_EMAIL` ausente ou user não encontrado |
| Cross-tenant via PATCH/GET/DELETE | Controllers usam `scoped_*` em todos os finders; teste de isolamento dedicado |
| Vazamento via Turbo Stream subscribe | Stream assinado `[user, :dashboard]` (não string previsível) |
| Pollution `Current.user` em SolidQueue | `ensure Current.reset` em job; spec específico de sequência user A → B |
| Admin legacy quebrar com OAuth | Lookup por email mantém `password_digest`; user pode continuar com senha |

---

## Validação Playwright executada

- Login admin@cronos-poc.local + bob@cronos-poc.local em browsers separados
- Confirmação 404 em URL cruzada (`/tasks/N` de outro tenant)
- Onboarding ponta-a-ponta: novo user OAuth → step 1 → empresa → step 2 → projeto → step 3 → task → dashboard normal com flash "Configuração concluída!"

---

## QA rounds aplicados

- **9.1:** 8 findings (CSS, accessibility, edge cases OAuth)
- **9.2:** 22 findings (4 CRITICAL + 6 HIGH + 8 MEDIUM + 4 LOW) — incluindo isolamento de Turbo Stream e `Current.session` em jobs
- **9.3:** 18 findings (1 CRITICAL + 5 HIGH + 7 MEDIUM + 5 LOW) — incluindo onboarding sem race em criação de Company

Lições catalogadas em `~/.claude/projects/-home-igor-rails-app-cronos-poc/memory/feedback_qa_9_*.md`.

---

## Suite resultante

- 1.120 examples passing
- 100% line coverage (802/802 linhas)
- Specs dedicados: `tenant_isolation_spec.rb`, `oauth_multi_tenant_integration_spec.rb`, `dashboard_onboarding_spec.rb`, `dashboard_broadcast_job_spec.rb`
