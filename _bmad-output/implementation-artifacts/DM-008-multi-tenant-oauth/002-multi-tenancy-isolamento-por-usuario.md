# Story 9.2: Multi-Tenancy — Isolamento de Dados por Usuário

**Status:** ready-for-review (implementado 2026-05-25)
**Domínio:** DM-008-multi-tenant-oauth
**Data:** 2026-05-15
**Epic:** Epic 9 — Multi-Tenancy & Google OAuth
**Story ID:** 9.2
**Story Key:** 9-2-multi-tenancy-isolamento-por-usuario
**Prioridade:** critical

---

## Contexto

Com login Google self-service (story 9.1), qualquer pessoa pode entrar — mas hoje o sistema é **single-tenant**: toda Company, Project, Task e TaskItem é visível para qualquer user autenticado. Isso é inaceitável quando o app é aberto.

Esta story implementa **multi-tenancy por user_id**: cada usuário enxerga apenas suas próprias entidades. É a maior mudança de banco/queries do projeto até hoje.

---

## História do Usuário

**Como** Igor (e qualquer novo usuário),
**Quero** que minhas Companies, Projects, Tasks e TaskItems sejam privadas e visíveis apenas para mim,
**Para** que o sistema funcione como SaaS multi-usuário onde meu histórico financeiro fica isolado dos demais.

---

## Critérios de Aceite

### AC1 — Migrations: adicionar user_id em todas as tabelas tenant
- [x] **AC1.1:** Migration adiciona `user_id` (bigint, null: false após backfill, foreign_key, indexed) em:
  - `companies`
  - `projects`
  - `tasks`
  - `task_items` (via inferência por `task.user_id`, mas adicionar coluna explícita para queries diretas)
- [x] **AC1.2:** Migration **separada** faz backfill: atribui todos os registros existentes ao user identificado por `ENV["INITIAL_TENANT_EMAIL"]` (ou primeiro user com `google_uid` presente)
- [x] **AC1.3:** Após backfill OK, migration final altera colunas para `null: false`

### AC2 — Associações Active Record
- [x] **AC2.1:** `User has_many :companies, dependent: :destroy`
- [x] **AC2.2:** `User has_many :projects, dependent: :destroy` (através de companies ou direto)
- [x] **AC2.3:** `User has_many :tasks, dependent: :destroy`
- [x] **AC2.4:** `User has_many :task_items, dependent: :destroy`
- [x] **AC2.5:** `Company belongs_to :user`, idem Project/Task/TaskItem

### AC3 — Scoping em controllers (escopo padrão por current_user)
- [x] **AC3.1:** `CompaniesController` — todas as actions usam `current_user.companies` em vez de `Company`
- [x] **AC3.2:** `ProjectsController` — idem `current_user.projects`
- [x] **AC3.3:** `TasksController` — todas as actions (`index`, `show`, `edit`, `update`, `destroy`, `deliver`, `reopen`) usam `current_user.tasks`
- [x] **AC3.4:** `TaskItemsController` — `current_user.task_items` ou `current_user.tasks.find(params[:task_id]).task_items`
- [x] **AC3.5:** `DashboardController` e `DashboardCalculations` concern — todas as queries (KPIs, totalizadores, lista) escopadas a `current_user`
- [x] **AC3.6:** Qualquer `Task.X` ou `Company.X` ou `Project.X` ou `TaskItem.X` no codebase auditado e substituído por scope do user

### AC4 — Strong params
- [x] **AC4.1:** Strong params **não permitem** `user_id` — sempre injetado server-side via `current_user`
- [x] **AC4.2:** Em `#create`: `current_user.tasks.create(task_params)` em vez de `Task.create`

### AC5 — Validações de integridade
- [x] **AC5.1:** Ao criar Task, validar que `company_id` e `project_id` pertencem ao `current_user` (não dá para atribuir Task a uma Company de outro usuário)
- [x] **AC5.2:** Custom validator `BelongsToCurrentUserValidator` ou validações simples nos models
- [x] **AC5.3:** Tentativa de acessar `/tasks/:id` de outro user → 404 (não 403 — vazaria existência)

### AC6 — Factories e specs atualizados
- [x] **AC6.1:** `FactoryBot` factories para `Company`, `Project`, `Task`, `TaskItem` criam um `User` por padrão (ou aceitam `user: x` explicitamente)
- [x] **AC6.2:** Todos os specs (~130+) que criam tasks/companies revisados — devem funcionar com factory atualizada
- [x] **AC6.3:** Novo spec de **isolamento**: user A não vê tasks de user B
- [x] **AC6.4:** Novo spec: tentar PATCH/GET/DELETE em recurso de outro user → 404

### AC7 — UI sem mudanças visíveis (exceto avatar/nome)
- [x] **AC7.1:** Navbar exibe `current_user.name` e `current_user.avatar_url` (já populados pelo Google na story 9.1)
- [x] **AC7.2:** Demais telas funcionam idênticas — listas/dashboards só passam a mostrar dados do user logado

---

## Análise Técnica

### Estratégia de migration em 3 passos

**Passo 1: adicionar colunas nullable**
```ruby
add_reference :companies, :user, foreign_key: true, null: true
add_reference :projects, :user, foreign_key: true, null: true
add_reference :tasks, :user, foreign_key: true, null: true
add_reference :task_items, :user, foreign_key: true, null: true
```

**Passo 2: backfill**
```ruby
# Em migration separada
initial_user = User.find_by(email: ENV.fetch("INITIAL_TENANT_EMAIL"))
initial_user ||= User.where.not(google_uid: nil).order(:created_at).first
raise "Nenhum user inicial encontrado" if initial_user.nil?

Company.where(user_id: nil).update_all(user_id: initial_user.id)
Project.where(user_id: nil).update_all(user_id: initial_user.id)
Task.where(user_id: nil).update_all(user_id: initial_user.id)
TaskItem.where(user_id: nil).update_all(user_id: initial_user.id)
```

**Passo 3: tornar `null: false`**
```ruby
change_column_null :companies, :user_id, false
# ... idem para os outros
```

### Padrão de scoping nos controllers

Em vez de espalhar `current_user.tasks` em cada action, criar um **concern**:

```ruby
# app/controllers/concerns/tenant_scoped.rb
module TenantScoped
  extend ActiveSupport::Concern
  private

  def scoped_companies; current_user.companies; end
  def scoped_projects; current_user.projects; end
  def scoped_tasks; current_user.tasks; end
  def scoped_task_items; current_user.task_items; end
end
```

E os controllers incluem `include TenantScoped`.

### Custom validator de integridade

```ruby
class BelongsToCurrentUserValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    # Valida apenas no contexto da request (Current.user)
    return unless Current.user
    associated_class = options[:class_name].constantize
    unless associated_class.where(id: value, user_id: Current.user.id).exists?
      record.errors.add(attribute, :not_yours)
    end
  end
end
```

Usar `CurrentAttributes` (Rails) para acessar `current_user` no model.

---

## Arquivos a Criar/Modificar

| Arquivo | Ação |
|---------|------|
| `db/migrate/YYYYMMDD_add_user_to_tenant_tables.rb` | Migration passo 1 |
| `db/migrate/YYYYMMDD_backfill_user_id_in_tenant_tables.rb` | Migration backfill |
| `db/migrate/YYYYMMDD_enforce_user_id_not_null.rb` | Migration passo 3 |
| `app/models/user.rb` | Adicionar associations has_many |
| `app/models/company.rb`, `project.rb`, `task.rb`, `task_item.rb` | Adicionar `belongs_to :user`, validators de integridade |
| `app/models/current.rb` | Criar `CurrentAttributes` (já existe em Rails 8) |
| `app/controllers/application_controller.rb` | `before_action :set_current_user` que faz `Current.user = current_user` |
| `app/controllers/concerns/tenant_scoped.rb` | Concern com scoped helpers |
| `app/controllers/companies_controller.rb`, `projects_controller.rb`, `tasks_controller.rb`, `task_items_controller.rb`, `dashboard_controller.rb` | Usar scoped_* methods |
| `app/controllers/concerns/dashboard_calculations.rb` | Escopar todas as queries por current_user |
| `spec/factories/*.rb` | Atualizar factories para criar/aceitar user |
| `spec/requests/tenant_isolation_spec.rb` | Criar — specs de isolamento entre users |
| `spec/**/*` | Revisão geral — 130+ specs |

---

## Testes Críticos

- [x] User A cria task → User B logado **não** vê no `/tasks` nem no dashboard
- [x] User B tenta GET `/tasks/:id_do_user_A` → 404
- [x] User B tenta PATCH/DELETE no recurso de A → 404
- [x] User A cria Task com `company_id` de Company de B → erro de validação
- [x] Backfill: rodar migration → todos os registros existentes amarrados ao user inicial
- [x] User inicial loga via Google → enxerga todo o histórico migrado

---

## Riscos e Mitigações

| Risco | Mitigação |
|-------|-----------|
| **Quebrar 130+ specs** | Migration de factory feita primeiro; rodar suite e ajustar em batch |
| **Esquecer um scope** | Auditoria estática via grep `Task\.\|Company\.\|Project\.\|TaskItem\.` excluindo specs/migrations; adicionar Rubocop rule custom |
| **Vazamento de dados** | Spec dedicado `tenant_isolation_spec.rb` cobre cenários cross-user para todos os controllers |
| **Backfill em prod sem user** | Migration valida `INITIAL_TENANT_EMAIL` ou falha; documentar ENV no deploy |
| **Performance: índices** | Cada `user_id` é indexed; queries existentes não pioram porque já filtram por contexto (mês, status etc) |

---

## Dependências

- **Requer:** story 9.1 (User com google_uid existindo)
- **Bloqueia:** story 9.3 (onboarding pós-login)

---

## Estimativa

**8 story points** (~12-16h) — é a maior story do projeto:
- 3 migrations
- Refactor de 5 controllers + 1 concern
- Validações de integridade em 4 models
- 130+ specs revisados (~70% deve passar sem mudança após ajuste de factory)
- 1 spec novo dedicado a isolamento

Considerar quebrar em sub-PRs por controller se ficar muito grande.

---

## Dev Agent Record

**Agent:** Amelia (bmad-agent-dev)
**Data:** 2026-05-25
**Branch:** `feature-002-multi-tenancy-isolamento-por-usuario`

### Resumo da implementação

1. **3 migrations** em sequência (add nullable → backfill → null:false) adicionaram `user_id` em `companies`, `projects`, `tasks`, `task_items`. Backfill resolve user inicial por `ENV["INITIAL_TENANT_EMAIL"]` → primeiro user com `google_uid` → primeiro user qualquer → no-op se DB vazio.
2. **Associations** `User has_many` e `belongs_to :user` em todos os 4 models tenant. `Company#name` agora é único **por user** (não global).
3. **`TenantScoped` concern** em `app/controllers/concerns/tenant_scoped.rb` expõe `scoped_companies/projects/tasks/task_items`. Incluído em `ApplicationController` (todos os controllers herdam) e em `DashboardBroadcastJob`.
4. **Custom validator** `BelongsToCurrentUserValidator` (app/validators) impede que Task referencie Company/Project de outro user. Aplicado em `Project#company_id` e `Task#company_id/project_id`. No-op fora de request (`Current.user` nil), respeitando factories/seeds.
5. **404 cross-user**: `ApplicationController.rescue_from RecordNotFound` retorna 404 (HTML/turbo_stream/json) — não vaza existência de IDs.
6. **Strong params** continuam não permitindo `user_id`; create flows usam `scoped_*.new` (injeção server-side).
7. **Endpoint `/projects/projects` (JSON)** que tinha skip de autenticação foi protegido — antes vazaria projetos de qualquer tenant.
8. **TaskItem callback** `before_validation :inherit_user_from_task` garante que `user_id` é herdado da Task pai (já que `@task.task_items.build` não propaga associations transitivas).
9. **DashboardBroadcastJob** refatorado para receber `user_id` opcional; broadcast vai para stream `dashboard_user_<id>` em vez do stream legado `dashboard`. Sintetiza session ephemeral para `Current.user` durante o job.
10. **Factories** atualizadas para herdar `user` entre Company/Project/Task/TaskItem. Spec helper `TenantFactoryHelper` provê fallback inteligente que reaproveita user de Session ativa no DB (controller specs) ou último User criado (request specs com `let!(:user)`).
11. **Navbar** (`app/views/layouts/application.html.erb`) exibe avatar e `name` do `Current.user` em desktop e mobile (fallback no email).
12. **Spec novo** `spec/requests/tenant_isolation_spec.rb` com 29 testes cobrindo: visibilidade isolada por index, 404 cross-user em todos os controllers, rejeição de cross-tenant via create, sanidade do BelongsToCurrentUserValidator.
13. **Seeds.rb** ajustado para amarrar companies ao admin user (multi-tenant ready).

### Suite & cobertura

- **999/999 specs passing** (`docker exec -e RAILS_ENV=test cronos-poc-web-1 bundle exec rspec`)
- **100% line coverage** (SimpleCov enforce minimum: 100)
- Tempo: ~47s

### Decisões e ajustes

- **Schema dump bug**: durante implementação, um `db:schema:dump` intermediário gerou `schema.rb` sem `user_id` em projects. Corrigido regenerando via `db:schema:dump` direto do dev DB.
- **Spec de migration `create_projects_spec.rb`** dropa e recria a tabela projects no rollback; ajustado para recriar **com** `user_id`, evitando inconsistência entre runs.
- **Helper transparente `TenantFactoryHelper`** evita reescrever ~130 specs antigos. Estratégia: factories `:company` priorizam (em ordem) `TenantFactoryHelper.current_test_user` → Session no DB → último User criado → novo User. Specs `let!(:user)` (promovidos via sed em massa) garantem que o user logado já existe antes da factory de Company.
- **3 specs de projects 404** atualizados de `redirect_to(projects_path) + alert "não encontrado"` para `:not_found` status — alinha com AC5.3.

### File List

#### Criados
- `db/migrate/20260525075147_add_user_to_tenant_tables.rb`
- `db/migrate/20260525075148_backfill_user_id_in_tenant_tables.rb`
- `db/migrate/20260525075149_enforce_user_id_not_null_on_tenant_tables.rb`
- `app/controllers/concerns/tenant_scoped.rb`
- `app/validators/belongs_to_current_user_validator.rb`
- `spec/requests/tenant_isolation_spec.rb`
- `spec/support/tenant_factory_helper.rb`

#### Modificados
- `app/controllers/application_controller.rb` — include TenantScoped + rescue 404
- `app/controllers/companies_controller.rb` — scoped_*
- `app/controllers/projects_controller.rb` — scoped_*, removido skip_auth do JSON endpoint
- `app/controllers/tasks_controller.rb` — scoped_*
- `app/controllers/task_items_controller.rb` — scoped_*
- `app/controllers/daily_summary_controller.rb` — scoped_task_items
- `app/controllers/dashboard_events_controller.rb` — scoped_tasks/task_items
- `app/controllers/concerns/dashboard_calculations.rb` — scoped_* em todos os cálculos
- `app/models/user.rb` — has_many companies/projects/tasks/task_items
- `app/models/company.rb` — belongs_to :user + uniqueness scoped
- `app/models/project.rb` — belongs_to :user + validator
- `app/models/task.rb` — belongs_to :user + validators + broadcast com user_id
- `app/models/task_item.rb` — belongs_to :user + inherit_user_from_task + broadcast com user_id
- `app/jobs/dashboard_broadcast_job.rb` — multi-tenant stream + Current.set
- `app/views/layouts/application.html.erb` — avatar/name na navbar (desktop + mobile)
- `db/schema.rb` — colunas user_id em 4 tabelas
- `db/seeds.rb` — companies amarradas ao admin
- `spec/factories/companies.rb` — fallback inteligente para user
- `spec/factories/projects.rb` — herda user de company
- `spec/factories/tasks.rb` — herda user de company
- `spec/factories/task_items.rb` — herda user de task
- `spec/jobs/dashboard_broadcast_job_spec.rb` — cobre multi-tenant + fallback nil
- `spec/migrations/create_projects_spec.rb` — recriação com user_id
- `spec/models/project_spec.rb` — user explícito
- `spec/controllers/tasks_controller_spec.rb` — let!(:user)/let!(:session) + user explícito na company
- `spec/requests/projects_spec.rb` — 3 specs 404 em vez de redirect
- `spec/requests/dashboard_modal_nova_tarefa_spec.rb` — user em company/project
- ~10 request specs `let(:user)` → `let!(:user)` via sed em massa (mobile_first, mobile_timeentry_form, responsividade, dashboard_modal, accessibility, dashboard_kpis, dashboard_tasks_month, dashboard_quick_actions, required_fields_pattern, tasks_spec)

---

## QA Fixes Applied (Round 2 — pós-review Quinn)

**Status:** ready-for-review (fixes aplicados 2026-05-25)
**Suite:** 1030/1030 specs passing, 100% line coverage (752/752 lines)

### CRITICAL (4 / 4 aplicados)

- **QA #1** — Removido `app/controllers/dashboard_events_controller.rb` (dead code, sem rota). Removido filter SimpleCov correspondente em `spec/spec_helper.rb`.
- **QA #2** — `app/views/dashboard/index.html.erb` agora usa `turbo_stream_from Current.user, :dashboard` (signed). `app/jobs/dashboard_broadcast_job.rb` broadcast em `[user, :dashboard]` (signed). Atacante não consegue subscrever stream de outro tenant via devtools.
- **QA #3, #21** — `app/models/current.rb` adicionou `user_override` (separado de session). Job não precisa mais sintetizar `Session.first_or_initialize` falsa.
- **QA #4** — `spec/support/tenant_factory_helper.rb` reescrito: prepend só dentro de `before(:suite)`, sem duplicação, sem rescue StandardError genérico, `before+after(:each) { TenantFactoryHelper.reset! }`.

### HIGH (6 / 6 aplicados)

- **QA #5** — `attr_readonly :user_id` em Company, Project, Task, TaskItem. Rails 8 levanta `ActiveRecord::ReadonlyAttributeError` ao tentar setar — defesa em profundidade contra mass-assignment.
- **QA #6** — `app/controllers/task_items_controller.rb#set_task_item` agora usa `scoped_task_items.where(task_id: @task.id).find(...)` (double-scope).
- **QA #7** — `db/migrate/20260525075148_backfill_user_id_in_tenant_tables.rb` refatorado com `say_with_time`, log do user escolhido (email + id), contagem por tabela, warnings quando cai no fallback não-determinístico.
- **QA #8** — TaskItem agora valida `user_id_matches_task_user_id` on create — rejeita mass-assign de user_id diferente da task.user_id.
- **QA #9** — `tasks_controller.rb:32` trocou `merge(Company.active)` por `where(companies: { active: true })` explícito.
- **QA #10** — `spec/rails_helper.rb` adicionou `before+after(:each) { Current.reset }`. `tenant_isolation_spec.rb` trocou `ensure` por `around` no describe do validator.

### MEDIUM (8 / 8 aplicados)

- **QA #11** — `spec/models/user_spec.rb` ganhou describe "multi-tenant cascade on destroy" com 4 specs validando: cascade bloqueado quando há projects (restrict_with_error), cascade completo quando árvore limpa, destroy sem dados, isolamento entre tenants. Comportamento documentado.
- **QA #12** — `db/seeds.rb` agora diferencia `new_record?` de existing — preserva `hourly_rate` em reseed. `spec/db/seeds_spec.rb` ganhou 2 specs novos cobrindo create + preserve.
- **QA #13** — Nova migration `20260525173854_add_composite_indexes_for_tenant_queries.rb` adicionou indexes `(user_id, work_date)` em task_items, `(user_id, start_date)` em tasks, `(user_id, active)` em companies.
- **QA #14** — Novo `spec/validators/belongs_to_current_user_validator_spec.rb` com positive case + negative case isolados (independente de controllers).
- **QA #15** — `application_controller.rb#render_not_found` agora usa `render plain: "Not Found"` (sem dependência de `Rails.public_path.join("404.html")` em runtime).
- **QA #16** — `dashboard_broadcast_job.rb` agora tem `ensure Current.reset` explícito. Spec "reseta Current mesmo se broadcast levantar exception" valida.
- **QA #17** — `spec/jobs/dashboard_broadcast_job_spec.rb` ganhou 5 specs novos: "seta Current.user durante broadcast", "reseta após", "Current nil quando user_id nil", "reset mesmo em exception", "sequência de jobs (A→B) não vaza tenant".
- **QA #18** — Coberto pela reescrita do TenantFactoryHelper (QA #4): cleanup simétrico `before+after`.

### LOW (4 / 4 aplicados)

- **QA #19** — `app/controllers/concerns/tenant_scoped.rb` ganhou `require_current_user!` + `MissingTenantError`. Loud failure quando endpoint público chama scoped_*. Novo `spec/controllers/concerns/tenant_scoped_spec.rb` cobre.
- **QA #20** — Comentário de `belongs_to_current_user_validator.rb` melhorado: explicita separação de concerns (FK vs presence vs validator).
- **QA #21** — Coberto pela refatoração #3 (`Current.user_override`).
- **QA #22** — Novo `spec/requests/oauth_multi_tenant_integration_spec.rb` com 4 specs: user_a vê só suas companies via OAuth, user_b vê só suas, 404 cross-tenant via URL direta, user novo via OAuth vê tela vazia.

### Arquivos criados (round 2)

- `db/migrate/20260525173854_add_composite_indexes_for_tenant_queries.rb`
- `spec/validators/belongs_to_current_user_validator_spec.rb`
- `spec/requests/oauth_multi_tenant_integration_spec.rb`
- `spec/controllers/concerns/tenant_scoped_spec.rb`

### Arquivos modificados (round 2)

- `app/controllers/application_controller.rb` — render plain 404
- `app/controllers/concerns/tenant_scoped.rb` — require_current_user! + MissingTenantError
- `app/controllers/task_items_controller.rb` — double-scope no set_task_item
- `app/controllers/tasks_controller.rb` — where(companies: { active: true }) explícito
- `app/jobs/dashboard_broadcast_job.rb` — stream assinado + Current.user_override + ensure reset
- `app/models/current.rb` — user_override attribute
- `app/models/company.rb` — attr_readonly :user_id
- `app/models/project.rb` — attr_readonly :user_id
- `app/models/task.rb` — attr_readonly :user_id
- `app/models/task_item.rb` — attr_readonly + user_id_matches_task_user_id validate
- `app/validators/belongs_to_current_user_validator.rb` — comentário melhorado
- `app/views/dashboard/index.html.erb` — turbo_stream_from assinado
- `db/migrate/20260525075148_backfill_user_id_in_tenant_tables.rb` — say_with_time + logs
- `db/seeds.rb` — diferenciar new_record de existing
- `spec/spec_helper.rb` — removido filter DashboardEventsController
- `spec/rails_helper.rb` — Current.reset hooks
- `spec/support/tenant_factory_helper.rb` — reescrito sem duplicação
- `spec/db/seeds_spec.rb` — 2 specs novos
- `spec/jobs/dashboard_broadcast_job_spec.rb` — 5 specs novos
- `spec/models/company_spec.rb` — spec attr_readonly
- `spec/models/project_spec.rb` — spec attr_readonly
- `spec/models/task_spec.rb` — spec attr_readonly
- `spec/models/task_item_spec.rb` — specs attr_readonly + user_id matches
- `spec/models/user_spec.rb` — 4 specs cascade
- `spec/requests/tenant_isolation_spec.rb` — around em vez de ensure

### Arquivos removidos (round 2)

- `app/controllers/dashboard_events_controller.rb`
