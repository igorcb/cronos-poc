# Story 13.3: KPI "Horas sem tarefa" no Dashboard

Status: ready-for-dev

<!-- Ultimate context engine analysis completed - comprehensive developer guide created -->

## Story

**Como** usuário do Cronos,

**Quero** ver no dashboard o total de horas "Sem Tarefa" no dia e no mês,

**Para que** eu tenha, ao final do período, um número objetivo para evidenciar disponibilidade não aproveitada por ausência de demanda.

## Acceptance Criteria

**Given** que existem `IdlePeriod`s registrados para o `Current.user`

**When** acesso o dashboard (`GET /`)

**Then**
1. um novo card de KPI "Horas sem tarefa (hoje)" exibe a soma de `hours` dos `IdlePeriod`s do dia corrente, escopados ao `Current.user`
2. um novo card de KPI "Horas sem tarefa (mês)" exibe a soma de `hours` dos `IdlePeriod`s do mês corrente, escopados ao `Current.user`
3. KPIs exibem `0` (não erro/nil) quando não há registros no período
4. cálculo usa `pluck(:hours).sum` em Ruby (não `SUM()` de SQL) — evita duplicação em eventual JOIN futuro, seguindo heurística firmada do projeto (ver architecture.md §7 e QA #019)

**Given** que crio ou removo um `IdlePeriod` (Stories 13.1/13.2)

**When** a ação é concluída com sucesso

**Then**
5. os KPIs "Horas sem tarefa (hoje)" e "Horas sem tarefa (mês)" são atualizados via Turbo Stream, sem reload de página
6. a atualização reaproveita o pipeline existente de `DashboardBroadcastJob` (broadcast assinado por user, `[user, :dashboard]`) — não criar canal novo

**Given** que analiso o código

**When** reviso a implementação

**Then**
7. os métodos de cálculo seguem o padrão de `DashboardCalculations` (mesmo concern usado por `calculate_daily_hours`, `calculate_monthly_hours`, etc.)
8. os cálculos de horas sem tarefa **não** alteram nenhum cálculo existente de horas trabalhadas/entregues (KPIs de Task/TaskItem permanecem intocados)

## Tasks / Subtasks

- [ ] Adicionar métodos de cálculo em `DashboardCalculations` concern
  - [ ] `calculate_daily_idle_hours` — soma `hours` de `IdlePeriod`s do `Current.user` com `work_date: Date.current`
  - [ ] `calculate_monthly_idle_hours` — soma `hours` de `IdlePeriod`s do `Current.user` com `work_date: Date.current.all_month`
  - [ ] Usar `.pluck(:hours).sum` (Ruby), não `.sum("hours")` (SQL), por consistência com heurística do projeto

- [ ] Adicionar `scoped_idle_periods` em `TenantScoped` concern
  - [ ] `def scoped_idle_periods; Current.user.idle_periods; end`

- [ ] Atualizar `DashboardController#index`
  - [ ] `@daily_idle_hours = calculate_daily_idle_hours`
  - [ ] `@monthly_idle_hours = calculate_monthly_idle_hours`

- [ ] Criar partials de KPI
  - [ ] `app/views/dashboard/_daily_idle_hours.html.erb`
  - [ ] `app/views/dashboard/_monthly_idle_hours.html.erb`
  - [ ] Adicionar os dois cards na grid de KPIs do dashboard (`app/views/dashboard/index.html.erb`)

- [ ] Atualizar `DashboardBroadcastJob`
  - [ ] Adicionar `daily_idle_hours` e `monthly_idle_hours` em `build_locals` e `zero_locals`
  - [ ] Adicionar os `turbo_stream.replace` correspondentes no partial de broadcast (`dashboard/broadcast_streams`)

- [ ] Conectar `IdlePeriodsController` (Story 13.2) ao broadcast
  - [ ] `create`/`destroy` devem enfileirar `DashboardBroadcastJob.perform_later(Current.user.id)` (mesmo padrão de `TaskItemsController`) OU retornar os `turbo_stream.replace` inline dos dois KPIs, consistente com o padrão síncrono já usado em `TaskItemsController#create`

## Dev Notes

### EPIC CONTEXT: Epic 13 — Disponibilidade sem Tarefa (DM-012)

Terceira story do epic — depende de `IdlePeriod` (13.1) e `IdlePeriodsController` (13.2). Esta story fecha o ciclo: sem o KPI visível, o registro criado nas stories anteriores não tem valor de evidência para o usuário.

### Previous Story Intelligence (13.1 e 13.2)

- `IdlePeriod` tem scope `by_user_and_month(user, date)` (Story 13.1) — pode ser reaproveitado ou substituído por query direta, à critério da implementação
- `IdlePeriodsController#create`/`destroy` (Story 13.2) responde `turbo_stream` fechando o modal — esta story precisa adicionar o `turbo_stream.replace` dos dois novos KPIs nessas respostas

### Architecture Compliance

**Reaproveitar `DashboardCalculations` concern (ver architecture.md §5, DA-101):**
```ruby
# app/controllers/concerns/dashboard_calculations.rb
module DashboardCalculations
  # ... métodos existentes (calculate_daily_hours, calculate_monthly_hours, etc.)

  def calculate_daily_idle_hours
    scoped_idle_periods.where(work_date: Date.current).pluck(:hours).sum
  end

  def calculate_monthly_idle_hours
    scoped_idle_periods.where(work_date: Date.current.all_month).pluck(:hours).sum
  end
end
```

**Heurística do projeto — `pluck + sum` em Ruby > `SUM()` em SQL multi-tabela (ver QA findings #019, architecture.md §7):**
Mesmo `IdlePeriod` sendo uma tabela simples sem JOIN necessário hoje, seguir o padrão estabelecido por consistência e para evitar duplicação futura caso a query evolua para incluir JOINs.

**`TenantScoped` — adicionar `scoped_idle_periods` (ver architecture.md §3):**
```ruby
# app/controllers/concerns/tenant_scoped.rb
def scoped_idle_periods
  Current.user.idle_periods
end
```

**`DashboardBroadcastJob` — reaproveitar pipeline existente, SEM criar canal novo (DA-101, decisão arquitetural explícita):**
```ruby
# app/jobs/dashboard_broadcast_job.rb
def build_locals(_user)
  {
    daily_hours:        calculate_daily_hours,
    monthly_hours:      calculate_monthly_hours,
    monthly_value:      calculate_monthly_value,
    daily_value:        calculate_daily_value,
    daily_task_count:   calculate_daily_task_count,
    monthly_task_count: calculate_monthly_task_count,
    daily_idle_hours:   calculate_daily_idle_hours,    # NOVO
    monthly_idle_hours: calculate_monthly_idle_hours,  # NOVO
    tasks:              monthly_tasks
  }
end

def zero_locals
  {
    daily_hours: 0, monthly_hours: 0, monthly_value: 0, daily_value: 0,
    daily_task_count: 0, monthly_task_count: 0,
    daily_idle_hours: 0, monthly_idle_hours: 0,  # NOVO
    tasks: Task.none
  }
end
```

**IMPORTANTE:** `DashboardBroadcastJob` já inclui `DashboardCalculations` e `TenantScoped` (ver job atual) — os novos métodos ficam automaticamente disponíveis, sem import adicional.

**Padrão de card de KPI (seguir estrutura visual dos KPIs existentes, ver Story 5.10):**
```erb
<!-- app/views/dashboard/_daily_idle_hours.html.erb -->
<div id="kpi-horas-sem-tarefa-hoje" class="<%= kpi_card_classes %>">
  <span class="kpi-label">Horas sem tarefa (hoje)</span>
  <span class="kpi-value"><%= number_with_precision(daily_idle_hours, precision: 2) %>h</span>
</div>
```

**Padrão Turbo Stream nos controllers de IdlePeriod (Story 13.2) — completar os streams pendentes:**
```ruby
# IdlePeriodsController#create / #destroy
render turbo_stream: [
  turbo_stream.action(:remove, "modal"),
  turbo_stream.replace("kpi-horas-sem-tarefa-hoje", partial: "dashboard/daily_idle_hours", locals: { daily_idle_hours: calculate_daily_idle_hours }),
  turbo_stream.replace("kpi-horas-sem-tarefa-mes", partial: "dashboard/monthly_idle_hours", locals: { monthly_idle_hours: calculate_monthly_idle_hours })
]
```
Isso resolve a nota deixada em aberto na Story 13.2 sobre a integração do KPI.

### File Structure Requirements

- Concern: `app/controllers/concerns/dashboard_calculations.rb` (editar, adicionar métodos)
- Concern: `app/controllers/concerns/tenant_scoped.rb` (editar, adicionar `scoped_idle_periods`)
- Controller: `app/controllers/dashboard_controller.rb` (editar, adicionar 2 ivars)
- Job: `app/jobs/dashboard_broadcast_job.rb` (editar, adicionar aos locals)
- Views: `app/views/dashboard/_daily_idle_hours.html.erb`, `app/views/dashboard/_monthly_idle_hours.html.erb` (novos)
- View: `app/views/dashboard/index.html.erb` (editar, adicionar 2 cards na grid)
- View: `app/views/dashboard/_broadcast_streams.html.erb` (editar, adicionar os 2 `turbo_stream.replace` — checar nome exato do partial usado pelo job)
- Controller: `app/controllers/idle_periods_controller.rb` (editar — Story 13.2 já criou, aqui só completa os streams de KPI)

### Testing Requirements

Specs completos são escopo da **Story 13.4**. Ao implementar, validar manualmente:
- KPIs mostram `0` sem registros
- KPIs somam corretamente múltiplos `IdlePeriod`s no mesmo dia/mês
- Criar/remover um `IdlePeriod` atualiza os KPIs sem reload

### Potential Pitfalls & Prevention

**1. Usar SQL `SUM()` em vez de `pluck + sum`:**
❌ ERRADO: `scoped_idle_periods.where(...).sum(:hours)` (gera SQL SUM, aceitável aqui mas inconsistente com o padrão do projeto se algum dia a query ganhar JOIN)
✅ CORRETO (padrão do projeto): `scoped_idle_periods.where(...).pluck(:hours).sum`

**2. Criar canal Turbo/ActionCable novo:**
❌ ERRADO: novo `broadcast_to` ou canal separado para IdlePeriod
✅ CORRETO: reaproveitar `DashboardBroadcastJob` e o stream assinado `[user, :dashboard]` já existente (DA-101)

**3. KPI quebra com `nil` quando não há registros:**
❌ ERRADO: `.sum(:hours)` sem `.pluck` pode retornar `nil` em edge cases de SQL customizado
✅ CORRETO: `pluck(:hours).sum` sempre retorna `0` para array vazio — comportamento seguro por padrão

**4. Esquecer de atualizar `zero_locals` no job (quebra broadcast legado sem user_id):**
✅ Garantir que `daily_idle_hours: 0, monthly_idle_hours: 0` estejam no `zero_locals` também

**5. Misturar cálculo de horas sem tarefa com horas trabalhadas:**
❌ ERRADO: somar `calculate_daily_hours + calculate_daily_idle_hours` em algum KPI existente
✅ CORRETO: KPIs de "sem tarefa" são exibidos **separadamente**, nunca combinados com horas trabalhadas (requisito de negócio central do DM-012 — ver product-brief.md)

### References

**PRD:**
- [prd.md — Epic 13, §7 Métricas de sucesso](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/prd.md) — "Evidência de horas sem tarefa disponível no mês"

**Architecture Decisions:**
- [architecture.md §6 — DA-101](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md) — "KPI calculado no DashboardController, broadcast via DashboardBroadcastJob existente"

**Referência de implementação (padrão a seguir):**
- [app/controllers/concerns/dashboard_calculations.rb](/home/igor/rails_app/cronos-poc/app/controllers/concerns/dashboard_calculations.rb) — métodos de cálculo existentes
- [app/jobs/dashboard_broadcast_job.rb](/home/igor/rails_app/cronos-poc/app/jobs/dashboard_broadcast_job.rb) — pipeline de broadcast a reaproveitar
- [app/controllers/dashboard_controller.rb](/home/igor/rails_app/cronos-poc/app/controllers/dashboard_controller.rb) — onde adicionar os ivars

**Previous Stories:**
- [13-1-model-idleperiod-migration.md](/home/igor/rails_app/cronos-poc/_bmad-output/implementation-artifacts/DM-012-registro-disponibilidade-sem-tarefa/13-1-model-idleperiod-migration.md)
- [13-2-idleperiodscontroller.md](/home/igor/rails_app/cronos-poc/_bmad-output/implementation-artifacts/DM-012-registro-disponibilidade-sem-tarefa/13-2-idleperiodscontroller.md)

### Definition of Done

- [ ] `calculate_daily_idle_hours` e `calculate_monthly_idle_hours` implementados em `DashboardCalculations`
- [ ] `scoped_idle_periods` adicionado em `TenantScoped`
- [ ] Dashboard exibe os 2 novos KPIs corretamente (0 quando vazio)
- [ ] `DashboardBroadcastJob` inclui os novos locals (build_locals e zero_locals)
- [ ] Criar/remover `IdlePeriod` atualiza os KPIs via Turbo Stream sem reload
- [ ] Nenhum KPI existente de horas trabalhadas foi alterado
- [ ] Rubocop sem ofensas

## Dev Agent Record

### Agent Model Used
_A preencher pelo dev agent na implementação._

### Debug Log References
_A preencher pelo dev agent na implementação._

### Completion Notes List
_A preencher pelo dev agent na implementação._

### File List
_A preencher pelo dev agent na implementação._
