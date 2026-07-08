# Story 13.1: Model IdlePeriod + Migration

Status: ready-for-dev

<!-- Ultimate context engine analysis completed - comprehensive developer guide created -->

## Story

**Como** usuário do Cronos sujeito a contrato de carga horária mínima mensal (190h) e máxima (300h),

**Quero** registrar períodos em que estive disponível para trabalhar mas não havia tarefa,

**Para que** eu tenha evidência formal e auditável de disponibilidade ociosa por ausência de demanda, distinta de indisponibilidade pessoal.

## Acceptance Criteria

**Given** que a tabela `users` existe

**When** crio a migration `CreateIdlePeriods`

**Then**
1. migration usa `create_table :idle_periods, if_not_exists: true`
2. possui `t.references :user, null: false, foreign_key: true, if_not_exists: true`
3. possui `t.time :start_time, null: false`
4. possui `t.time :end_time, null: false`
5. possui `t.date :work_date, null: false` (segue padrão de `task_items.work_date` — necessário porque `time` sozinho não localiza o registro no calendário)
6. possui `t.decimal :hours, precision: 10, scale: 2, null: false`
7. possui timestamps
8. índices criados: `user_id`, `[user_id, work_date]` com `if_not_exists: true`
9. `rails db:migrate` executa sem erros

**Given** que a migration foi executada

**When** crio o model `IdlePeriod`

**Then**
10. model possui `belongs_to :user`
11. model possui `attr_readonly :user_id` (padrão multi-tenant de `TaskItem`, story 9.2 QA #5 — impede mudança de tenant pós-criação)
12. model possui validações de presence: `start_time`, `end_time`, `work_date`
13. model possui validação customizada: `end_time` deve ser posterior a `start_time`
14. model possui `before_save :calculate_hours` que calcula `(end_time - start_time) / 3600.0`, arredondado a 2 casas decimais
15. `IdlePeriod` **NÃO** possui nenhuma associação com `Task`, `Company` ou `Project` — é uma entidade independente, sem overlap check no MVP (DA-102)
16. `IdlePeriod` **NÃO** entra em nenhum cálculo de `validated_hours`/`hourly_rate`/`delivered_value` de Task — total de horas ociosas é um KPI paralelo, não soma nas horas trabalhadas (requisito de negócio central do DM-012)

## Tasks / Subtasks

- [ ] Criar migration `CreateIdlePeriods`
  - [ ] Usar `create_table :idle_periods, if_not_exists: true`
  - [ ] Adicionar coluna `user_id` (`t.references :user, null: false, foreign_key: true, if_not_exists: true`)
  - [ ] Adicionar coluna `start_time` (`t.time`, `null: false`)
  - [ ] Adicionar coluna `end_time` (`t.time`, `null: false`)
  - [ ] Adicionar coluna `work_date` (`t.date`, `null: false`)
  - [ ] Adicionar coluna `hours` (`t.decimal`, `precision: 10, scale: 2`, `null: false`)
  - [ ] Adicionar timestamps
  - [ ] Criar índice em `user_id` com `if_not_exists: true`
  - [ ] Criar índice composto `[user_id, work_date]` com `if_not_exists: true`
  - [ ] Executar `rails db:migrate`

- [ ] Criar model `IdlePeriod` (`app/models/idle_period.rb`)
  - [ ] Adicionar `belongs_to :user`
  - [ ] Adicionar `attr_readonly :user_id`
  - [ ] Adicionar `validates :start_time, presence: true`
  - [ ] Adicionar `validates :end_time, presence: true`
  - [ ] Adicionar `validates :work_date, presence: true`
  - [ ] Adicionar validação customizada `end_time_after_start_time`
  - [ ] Adicionar callback `before_save :calculate_hours`
  - [ ] Adicionar scopes: `scope :by_user_and_month, ->(user, date) { where(user:, work_date: date.all_month) }`

- [ ] Adicionar associação em `User`
  - [ ] `has_many :idle_periods, dependent: :destroy` em `app/models/user.rb`

- [ ] Criar factory (`spec/factories/idle_periods.rb`)
  - [ ] Trait padrão: `start_time '09:00'`, `end_time '11:00'`, `work_date Date.current`
  - [ ] Trait `:long_duration` (ex: manhã inteira, 4h)

- [ ] Testar migration
  - [ ] Executar `rails db:migrate`
  - [ ] Verificar se tabela e índices foram criados

## Dev Notes

### EPIC CONTEXT: Epic 13 — Disponibilidade sem Tarefa (DM-012)

**Motivação de negócio (não é tech debt, é requisito contratual):**
Igor trabalha sob contrato com mínimo de 190h/mês e máximo de 300h/mês, mas nem sempre há tarefa disponível para preencher a disponibilidade. Sem este registro, o Cronos não distingue "não trabalhei porque não quis/pude" de "não trabalhei porque não havia demanda". Esta story é a fundação de dados para essa evidência.

**Esta é a PRIMEIRA story do Epic 13.** Não há story anterior neste epic — sem "Previous Story Intelligence" a aplicar. O padrão de referência mais próximo é a Story 4.2 (TaskItem), reaproveitado com adaptações multi-tenant.

**Decisão arquitetural crítica (DA-100, ver architecture.md):**
`IdlePeriod` é um **model completamente separado** de `Task`/`TaskItem` — não reaproveitar Task com flag/tipo. Motivo: evita contaminar a lógica de status automático (`pending → completed → delivered`), snapshots financeiros (`hourly_rate`, `delivered_value`) e validações de Task. Horas de `IdlePeriod` não somam no total de horas trabalhadas por design — essa é a regra de negócio central, não um detalhe de implementação.

### Architecture Compliance

**Multi-tenancy — Defense in Depth (aplicar OBRIGATORIAMENTE, ver architecture.md §3):**
```ruby
# 1. belongs_to :user direto (sem Company/Project/Task no meio)
belongs_to :user
attr_readonly :user_id   # impede trocar de tenant após create — padrão de TaskItem

# 2. Não usar belongs_to_current_user validator aqui —
#    esse validator serve para validar que uma FK aponta pra um registro
#    de OUTRO model que pertence ao tenant (ex: task.company_id).
#    IdlePeriod não tem esse tipo de referência cruzada (não pertence a
#    Task/Company/Project), então não se aplica.
```

O controller (Story 13.2) é quem vai garantir `Current.user.idle_periods.build(...)` em vez de aceitar `user_id` vindo de params — strong params NUNCA devem permitir `:user_id` (regra absoluta do projeto, ver architecture.md §3 "Strong params NUNCA permitem user_id").

**Padrão `if_not_exists: true` (OBRIGATÓRIO em toda migration do projeto):**
```ruby
create_table :idle_periods, if_not_exists: true do |t|
  t.references :user, null: false, foreign_key: true, if_not_exists: true
  # ...
end

add_index :idle_periods, :user_id, if_not_exists: true
add_index :idle_periods, [ :user_id, :work_date ], if_not_exists: true
```

**Tipos de dados (seguir padrão de TaskItem):**
- `time` para `start_time`/`end_time` (hora apenas, sem data — mesmo padrão de TaskItem)
- `date` para `work_date` (localiza o registro no calendário — TaskItem também tem esse campo, necessário porque dois `time` puros não bastam para saber "qual dia")
- `decimal precision: 10, scale: 2` para `hours` (NUNCA Float — regra do projeto, ver Potential Pitfalls da Story 4.2)

**Cálculo de horas (mesma fórmula de TaskItem.calculate_hours_worked):**
```ruby
def calculate_hours
  return unless start_time.present? && end_time.present?

  duration_in_seconds = (end_time - start_time)
  self.hours = (duration_in_seconds / 3600.0).round(2)
end
```

**Validação de end_time > start_time (mesmo padrão de TaskItem):**
```ruby
def end_time_after_start_time
  return unless start_time.present? && end_time.present?

  if end_time <= start_time
    errors.add(:end_time, "deve ser posterior à hora inicial")
  end
end
```

### File Structure Requirements

**Paths (Rails Conventions):**
- Migration: `db/migrate/YYYYMMDDHHMMSS_create_idle_periods.rb`
- Model: `app/models/idle_period.rb`
- Factory: `spec/factories/idle_periods.rb`
- Tests (não desta story — cobertos na 13.4): `spec/models/idle_period_spec.rb`

**Naming Conventions:**
- Table: `idle_periods` (snake_case plural)
- Model: `IdlePeriod` (CamelCase singular)
- Foreign Key: `user_id` (snake_case singular + `_id`)

**Associação em User:**
```ruby
# app/models/user.rb
class User < ApplicationRecord
  # ... associações existentes (companies, sessions, etc.)
  has_many :idle_periods, dependent: :destroy
end
```

### Testing Requirements

Cobertura completa de testes (model spec, request spec, controller) é escopo da **Story 13.4** — não desta story. Nesta story (13.1), apenas a factory é necessária como pré-requisito para as próximas stories do epic escreverem specs.

**Factory (padrão FactoryBot do projeto, ver spec/factories/task_items.rb):**
```ruby
FactoryBot.define do
  factory :idle_period do
    user { association :user }
    start_time { "09:00" }
    end_time { "11:00" }
    work_date { Date.current }

    trait :long_duration do
      start_time { "08:00" }
      end_time { "12:00" }
    end
  end
end
```

### Potential Pitfalls & Prevention

**1. Reaproveitar Task/TaskItem em vez de criar model novo:**
❌ ERRADO: adicionar `type: 'idle'` ou flag em Task
✅ CORRETO: model `IdlePeriod` totalmente separado (DA-100)

**2. Esquecer `if_not_exists: true` em migration:**
❌ ERRADO: `create_table :idle_periods do |t|`
✅ CORRETO: `create_table :idle_periods, if_not_exists: true do |t|`

**3. Usar Float para horas:**
❌ ERRADO: `t.float :hours`
✅ CORRETO: `t.decimal :hours, precision: 10, scale: 2`

**4. Permitir user_id vindo de params (será tratado no controller, Story 13.2, mas o model deve suportar isso):**
❌ ERRADO: model sem `attr_readonly :user_id` permite job/console trocar tenant depois do create
✅ CORRETO: `attr_readonly :user_id`, igual TaskItem

**5. Esquecer índice composto `[user_id, work_date]`:**
Necessário para a Story 13.3 (KPI de horas sem tarefa por dia/mês) não fazer table scan.
✅ CORRETO: `add_index :idle_periods, [ :user_id, :work_date ], if_not_exists: true`

**6. Adicionar validação `belongs_to_current_user`:**
Esse validator (`app/validators/belongs_to_current_user_validator.rb`) serve para validar FKs que apontam para OUTRO model tenant-scoped (ex: `task.company_id` aponta pra Company de outro user). `IdlePeriod.user_id` é a própria FK de tenant, não uma referência cruzada — não se aplica aqui. Não adicionar por engano.

### References

**PRD:**
- [prd.md — Epic 13](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/prd.md) — contexto de negócio e critério de sucesso

**Product Brief (fonte da decisão de negócio):**
- [DM-012-registro-disponibilidade-sem-tarefa/product-brief.md](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/DM-012-registro-disponibilidade-sem-tarefa/product-brief.md)

**Architecture Decisions:**
- [architecture.md §3 — Modelo de domínio](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md) — entidade IdlePeriod documentada
- [architecture.md §6 — DA-100, DA-101, DA-102](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md) — decisões arquiteturais desta feature

**Epics:**
- [epics.md — Epic 13](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/epics.md) — todas as 4 stories do epic

**Referência de implementação (padrão a seguir, model análogo):**
- [app/models/task_item.rb](/home/igor/rails_app/cronos-poc/app/models/task_item.rb) — padrão de model multi-tenant com `attr_readonly :user_id`, cálculo de horas via `before_save`, validação de `end_time > start_time`
- [Story 4.2 — TaskItem](/home/igor/rails_app/cronos-poc/_bmad-output/implementation-artifacts/DM-004-registro-tempo/003-criar-model-taskitem-com-validacoes-calculos.md) — story de referência com o mesmo tipo de model

### Definition of Done

- [ ] Migration executada sem erros
- [ ] Model `IdlePeriod` criado com validações, callback de cálculo de horas e `attr_readonly :user_id`
- [ ] Associação `belongs_to :user` funcionando
- [ ] Associação `has_many :idle_periods` adicionada em `User`
- [ ] Validação `end_time_after_start_time` testada manualmente (specs formais ficam para Story 13.4)
- [ ] Callback `calculate_hours` calculando corretamente
- [ ] Factory criada com trait `:long_duration`
- [ ] Rubocop sem ofensas
- [ ] Nenhuma alteração em `Task`/`TaskItem`/cálculos de horas trabalhadas existentes

## Dev Agent Record

### Agent Model Used
_A preencher pelo dev agent na implementação._

### Debug Log References
_A preencher pelo dev agent na implementação._

### Completion Notes List
_A preencher pelo dev agent na implementação._

### File List
_A preencher pelo dev agent na implementação._
