# Story 9.2: Multi-Tenancy — Isolamento de Dados por Usuário

**Status:** ready-for-dev (depende de 9.1)
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
- [ ] **AC1.1:** Migration adiciona `user_id` (bigint, null: false após backfill, foreign_key, indexed) em:
  - `companies`
  - `projects`
  - `tasks`
  - `task_items` (via inferência por `task.user_id`, mas adicionar coluna explícita para queries diretas)
- [ ] **AC1.2:** Migration **separada** faz backfill: atribui todos os registros existentes ao user identificado por `ENV["INITIAL_TENANT_EMAIL"]` (ou primeiro user com `google_uid` presente)
- [ ] **AC1.3:** Após backfill OK, migration final altera colunas para `null: false`

### AC2 — Associações Active Record
- [ ] **AC2.1:** `User has_many :companies, dependent: :destroy`
- [ ] **AC2.2:** `User has_many :projects, dependent: :destroy` (através de companies ou direto)
- [ ] **AC2.3:** `User has_many :tasks, dependent: :destroy`
- [ ] **AC2.4:** `User has_many :task_items, dependent: :destroy`
- [ ] **AC2.5:** `Company belongs_to :user`, idem Project/Task/TaskItem

### AC3 — Scoping em controllers (escopo padrão por current_user)
- [ ] **AC3.1:** `CompaniesController` — todas as actions usam `current_user.companies` em vez de `Company`
- [ ] **AC3.2:** `ProjectsController` — idem `current_user.projects`
- [ ] **AC3.3:** `TasksController` — todas as actions (`index`, `show`, `edit`, `update`, `destroy`, `deliver`, `reopen`) usam `current_user.tasks`
- [ ] **AC3.4:** `TaskItemsController` — `current_user.task_items` ou `current_user.tasks.find(params[:task_id]).task_items`
- [ ] **AC3.5:** `DashboardController` e `DashboardCalculations` concern — todas as queries (KPIs, totalizadores, lista) escopadas a `current_user`
- [ ] **AC3.6:** Qualquer `Task.X` ou `Company.X` ou `Project.X` ou `TaskItem.X` no codebase auditado e substituído por scope do user

### AC4 — Strong params
- [ ] **AC4.1:** Strong params **não permitem** `user_id` — sempre injetado server-side via `current_user`
- [ ] **AC4.2:** Em `#create`: `current_user.tasks.create(task_params)` em vez de `Task.create`

### AC5 — Validações de integridade
- [ ] **AC5.1:** Ao criar Task, validar que `company_id` e `project_id` pertencem ao `current_user` (não dá para atribuir Task a uma Company de outro usuário)
- [ ] **AC5.2:** Custom validator `BelongsToCurrentUserValidator` ou validações simples nos models
- [ ] **AC5.3:** Tentativa de acessar `/tasks/:id` de outro user → 404 (não 403 — vazaria existência)

### AC6 — Factories e specs atualizados
- [ ] **AC6.1:** `FactoryBot` factories para `Company`, `Project`, `Task`, `TaskItem` criam um `User` por padrão (ou aceitam `user: x` explicitamente)
- [ ] **AC6.2:** Todos os specs (~130+) que criam tasks/companies revisados — devem funcionar com factory atualizada
- [ ] **AC6.3:** Novo spec de **isolamento**: user A não vê tasks de user B
- [ ] **AC6.4:** Novo spec: tentar PATCH/GET/DELETE em recurso de outro user → 404

### AC7 — UI sem mudanças visíveis (exceto avatar/nome)
- [ ] **AC7.1:** Navbar exibe `current_user.name` e `current_user.avatar_url` (já populados pelo Google na story 9.1)
- [ ] **AC7.2:** Demais telas funcionam idênticas — listas/dashboards só passam a mostrar dados do user logado

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

- [ ] User A cria task → User B logado **não** vê no `/tasks` nem no dashboard
- [ ] User B tenta GET `/tasks/:id_do_user_A` → 404
- [ ] User B tenta PATCH/DELETE no recurso de A → 404
- [ ] User A cria Task com `company_id` de Company de B → erro de validação
- [ ] Backfill: rodar migration → todos os registros existentes amarrados ao user inicial
- [ ] User inicial loga via Google → enxerga todo o histórico migrado

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
