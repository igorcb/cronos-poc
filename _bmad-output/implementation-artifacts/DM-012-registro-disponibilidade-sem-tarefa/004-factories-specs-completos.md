# Story 13.4: Factories + Specs Completos

Status: ready-for-dev

<!-- Ultimate context engine analysis completed - comprehensive developer guide created -->

## Story

**Como** mantenedor do Cronos,

**Quero** cobertura de testes completa (model, controller, request, dashboard KPI) para a feature de Disponibilidade sem Tarefa,

**Para que** a feature tenha a mesma garantia de qualidade do resto do projeto (100% line coverage enforced no CI) e regressões sejam detectadas automaticamente.

## Acceptance Criteria

**Given** que `IdlePeriod`, `IdlePeriodsController` e os KPIs do dashboard estão implementados (Stories 13.1-13.3)

**When** executo a suite de specs

**Then**
1. `spec/models/idle_period_spec.rb` cobre: validações de presence, validação `end_time_after_start_time`, callback `calculate_hours` (incluindo arredondamento), `attr_readonly :user_id`, associação `belongs_to :user`, scope `by_user_and_month`
2. `spec/factories/idle_periods.rb` está completo com trait `:long_duration` (já criado na Story 13.1) e qualquer trait adicional necessário para os specs desta story
3. `spec/requests/idle_periods_spec.rb` cobre: criação bem-sucedida (turbo_stream fecha modal), criação com erro de validação (turbo_stream re-renderiza modal), destroy bem-sucedido, **destroy cross-tenant retorna 404**, tentativa de acesso não autenticado redireciona para login
4. specs de `DashboardController`/`dashboard_calculations_spec` (ou request spec do dashboard) cobrem: KPI "Horas sem tarefa (hoje)" e "(mês)" com 0 registros, com 1 registro, com múltiplos registros em dias diferentes do mês
5. cobertura de linha permanece **100%** (gate do CI) — todo código novo das Stories 13.1-13.3 precisa estar coberto
6. `bundle exec rubocop` não aponta ofensas nos arquivos novos/modificados

**Given** que os specs multi-tenant são escritos

**When** valido isolamento entre usuários

**Then**
7. existe pelo menos 1 spec que cria `IdlePeriod` para User A e tenta acessar/destruir via `Current.user` = User B, validando 404
8. specs seguem a heurística do projeto: nenhuma asserção usa `include("texto curto")` sem contexto específico (ver heurísticas firmadas, architecture.md §7)

## Tasks / Subtasks

- [ ] Completar/revisar `spec/factories/idle_periods.rb`
  - [ ] Confirmar trait padrão e `:long_duration` (criados na Story 13.1)
  - [ ] Adicionar traits necessários para cenários de teste desta story, se algum faltar (ex: `:yesterday`, `:different_month`)

- [ ] Criar `spec/models/idle_period_spec.rb`
  - [ ] `it { should belong_to(:user) }`
  - [ ] `it { should validate_presence_of(:start_time) }`
  - [ ] `it { should validate_presence_of(:end_time) }`
  - [ ] `it { should validate_presence_of(:work_date) }`
  - [ ] Teste de validação customizada `end_time_after_start_time` (válido e inválido)
  - [ ] Teste de callback `calculate_hours` — casos com arredondamento (ex: 08:00-12:15 → 4.25h)
  - [ ] Teste de `attr_readonly :user_id` — tentar mudar `user_id` após save e verificar que não muda
  - [ ] Teste de scope `by_user_and_month`

- [ ] Criar `spec/requests/idle_periods_spec.rb`
  - [ ] `POST /idle_periods` com params válidos — sucesso, turbo_stream, registro persistido com `user_id` do usuário autenticado
  - [ ] `POST /idle_periods` com params inválidos — turbo_stream re-renderiza modal com erros
  - [ ] `DELETE /idle_periods/:id` do próprio usuário — sucesso
  - [ ] `DELETE /idle_periods/:id` de outro usuário — **404**
  - [ ] `GET /idle_periods/new` sem autenticação — redirect para login
  - [ ] `POST /idle_periods` sem autenticação — redirect para login

- [ ] Adicionar/estender specs de dashboard
  - [ ] Cobrir `calculate_daily_idle_hours` e `calculate_monthly_idle_hours` (0, 1, múltiplos registros)
  - [ ] Cobrir isolamento multi-tenant dos KPIs (User A não vê horas ociosas de User B)
  - [ ] Cobrir atualização via turbo_stream após criar/remover `IdlePeriod` (request spec no dashboard ou no idle_periods_spec)

- [ ] Rodar suite completa e validar cobertura
  - [ ] `docker exec cronos-poc-web-1 bundle exec rspec` (ou comando equivalente do projeto)
  - [ ] Confirmar SimpleCov reporta 100% line coverage
  - [ ] `docker exec cronos-poc-web-1 bundle exec rubocop` sem ofensas

## Dev Notes

### EPIC CONTEXT: Epic 13 — Disponibilidade sem Tarefa (DM-012)

Última story do epic — fecha a feature com a mesma disciplina de testes usada em todo o resto do projeto (1.120+ specs, 100% line coverage enforced no CI, ver architecture.md §7). Depende de 13.1, 13.2 e 13.3 estarem implementadas.

### Previous Story Intelligence (13.1, 13.2, 13.3)

- Model `IdlePeriod`: `belongs_to :user`, `attr_readonly :user_id`, validações de presence + `end_time_after_start_time`, callback `calculate_hours`, scope `by_user_and_month`
- Controller `IdlePeriodsController`: rotas `new`/`create`/`destroy`, scoping via `Current.user.idle_periods`, strong params sem `:user_id`
- Dashboard: `calculate_daily_idle_hours`/`calculate_monthly_idle_hours` em `DashboardCalculations`, `scoped_idle_periods` em `TenantScoped`, integração com `DashboardBroadcastJob`

### Architecture Compliance

**Padrão de testes do projeto (ver architecture.md §7):**

| Tipo | Referência de padrão |
|------|----------------------|
| Model specs | `spec/models/task_item_spec.rb` — Shoulda Matchers para validações/associações |
| Request specs | `spec/requests/task_items_spec.rb` — turbo_stream + multi-tenant 404 |
| Factory | `spec/factories/task_items.rb` — traits |

**Heurísticas firmadas do projeto a seguir OBRIGATORIAMENTE (ver architecture.md §7, memória do projeto):**
1. Não usar `include("texto curto")` em asserções de string — usar regex ou string com contexto específico completo, evita falso positivo
2. Validar `I18n.t(...).is_a?(Array)` antes de indexar, se aplicável
3. `pluck + sum` em Ruby > `SUM()` de SQL multi-tabela (já aplicado na Story 13.3)
4. Specs de multi-tenancy devem verificar isolamento **real** — criar registro de outro user explicitamente e tentar acessar, não apenas testar o "happy path" do próprio usuário

**Exemplo de spec de model (adaptar de `spec/models/task_item_spec.rb`):**
```ruby
# spec/models/idle_period_spec.rb
require "rails_helper"

RSpec.describe IdlePeriod, type: :model do
  it { should belong_to(:user) }
  it { should validate_presence_of(:start_time) }
  it { should validate_presence_of(:end_time) }
  it { should validate_presence_of(:work_date) }

  describe "#end_time_after_start_time" do
    it "é inválido quando end_time é anterior a start_time" do
      idle_period = build(:idle_period, start_time: "10:00", end_time: "09:00")
      expect(idle_period).not_to be_valid
      expect(idle_period.errors[:end_time]).to include("deve ser posterior à hora inicial")
    end
  end

  describe "#calculate_hours" do
    it "calcula horas corretamente com arredondamento" do
      idle_period = build(:idle_period, start_time: "08:00", end_time: "12:15")
      idle_period.save!
      expect(idle_period.hours).to eq(4.25)
    end
  end

  describe "attr_readonly :user_id" do
    it "não permite alterar user_id após criação" do
      idle_period = create(:idle_period)
      other_user = create(:user)
      idle_period.update(user_id: other_user.id)
      expect(idle_period.reload.user_id).not_to eq(other_user.id)
    end
  end
end
```

**Exemplo de spec de request multi-tenant (adaptar de padrão de `task_items_spec.rb`):**
```ruby
# spec/requests/idle_periods_spec.rb
require "rails_helper"

RSpec.describe "IdlePeriods", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before { sign_in_as(user) } # usar helper de autenticação existente no projeto

  describe "DELETE /idle_periods/:id" do
    it "retorna 404 ao tentar destruir período de outro usuário" do
      idle_period = create(:idle_period, user: other_user)

      delete idle_period_path(idle_period)

      expect(response).to have_http_status(:not_found)
    end

    it "destrói com sucesso período do próprio usuário" do
      idle_period = create(:idle_period, user: user)

      expect {
        delete idle_period_path(idle_period)
      }.to change(IdlePeriod, :count).by(-1)
    end
  end
end
```

**IMPORTANTE:** verificar o helper de autenticação real usado nos request specs existentes do projeto (`sign_in_as` é um placeholder — usar o padrão já estabelecido em `spec/requests/task_items_spec.rb` ou `spec/support/`).

### File Structure Requirements

- `spec/factories/idle_periods.rb` (criado na Story 13.1, revisar/completar aqui)
- `spec/models/idle_period_spec.rb` (novo)
- `spec/requests/idle_periods_spec.rb` (novo)
- Specs de dashboard: estender arquivo existente (ex: `spec/requests/dashboard_spec.rb` ou `spec/controllers/dashboard_controller_spec.rb` — usar o que já existe no projeto para os outros KPIs)

### Testing Requirements

Esta story **é** sobre testes — não há "requisito de teste" separado do próprio escopo. O critério de sucesso é 100% de cobertura de linha nos arquivos novos/modificados das Stories 13.1-13.3, mantendo o gate de CI existente (SimpleCov 100% line, ver architecture.md §8 CI/CD).

### Potential Pitfalls & Prevention

**1. Testar isolamento multi-tenant só no "happy path":**
❌ ERRADO: só testar que o próprio usuário consegue criar/ver seus registros
✅ CORRETO: testar explicitamente que User A não acessa/destrói registros de User B (404)

**2. Assertions frágeis com `include`:**
❌ ERRADO: `expect(response.body).to include("erro")`
✅ CORRETO: `expect(idle_period.errors[:end_time]).to include("deve ser posterior à hora inicial")` (mensagem específica e completa)

**3. Esquecer de testar `attr_readonly`:**
Model tem esse comportamento por decisão explícita de segurança multi-tenant (DA-100/Story 13.1) — precisa de spec dedicado, não é comportamento óbvio de testar por acaso.

**4. Deixar cobertura abaixo de 100% e CI quebrar:**
Rodar a suite completa com SimpleCov antes de considerar a story concluída — não assumir que "parece coberto".

**5. Duplicar setup de autenticação em vez de reaproveitar helpers existentes:**
Verificar `spec/support/` para helpers de login/autenticação já usados em `task_items_spec.rb` e replicar o mesmo padrão, não inventar um novo.

### References

**Architecture:**
- [architecture.md §7 — Estratégia de testes](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md) — heurísticas firmadas via 72 QA findings

**Referência de implementação (padrão a seguir):**
- `spec/models/task_item_spec.rb` — padrão de model spec com Shoulda Matchers
- `spec/requests/task_items_spec.rb` — padrão de request spec com multi-tenant 404
- `spec/factories/task_items.rb` — padrão de factory com traits

**Previous Stories:**
- [001-model-idleperiod-migration.md](/home/igor/rails_app/cronos-poc/_bmad-output/implementation-artifacts/DM-012-registro-disponibilidade-sem-tarefa/001-model-idleperiod-migration.md)
- [002-idleperiodscontroller.md](/home/igor/rails_app/cronos-poc/_bmad-output/implementation-artifacts/DM-012-registro-disponibilidade-sem-tarefa/002-idleperiodscontroller.md)
- [003-kpi-horas-sem-tarefa-dashboard.md](/home/igor/rails_app/cronos-poc/_bmad-output/implementation-artifacts/DM-012-registro-disponibilidade-sem-tarefa/003-kpi-horas-sem-tarefa-dashboard.md)

### Definition of Done

- [ ] `spec/models/idle_period_spec.rb` completo e passando
- [ ] `spec/requests/idle_periods_spec.rb` completo e passando (incluindo 404 cross-tenant)
- [ ] Specs de dashboard cobrindo os 2 novos KPIs
- [ ] Cobertura de linha 100% mantida (SimpleCov)
- [ ] Rubocop sem ofensas
- [ ] Nenhum spec existente quebrado (regressão zero)

## Dev Agent Record

### Agent Model Used
_A preencher pelo dev agent na implementação._

### Debug Log References
_A preencher pelo dev agent na implementação._

### Completion Notes List
_A preencher pelo dev agent na implementação._

### File List
_A preencher pelo dev agent na implementação._
