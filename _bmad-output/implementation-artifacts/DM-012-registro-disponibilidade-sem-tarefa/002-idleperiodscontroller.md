# Story 13.2: IdlePeriodsController

Status: done

<!-- Ultimate context engine analysis completed - comprehensive developer guide created -->

## Story

**Como** usuário do Cronos,

**Quero** registrar (criar) e remover períodos "Sem Tarefa" através de um modal no dashboard,

**Para que** eu consiga marcar rapidamente início/fim de disponibilidade ociosa sem sair do fluxo normal de uso.

## Acceptance Criteria

**Given** que o model `IdlePeriod` existe (Story 13.1)

**When** acesso a rota de criação de período sem tarefa

**Then**
1. [x] rota `GET /idle_periods/new` renderiza modal Turbo Frame (`#modal`) com formulário de `start_time`, `end_time`, `work_date`
2. [x] rota `POST /idle_periods` cria o registro escopado ao `Current.user` (nunca aceita `user_id` de params)
3. [x] em sucesso, resposta `turbo_stream` fecha o modal (atualização dos totalizadores do KPI é escopo da Story 13.3, ainda não implementada)
4. [x] em falha de validação, resposta `turbo_stream` re-renderiza o modal com mensagens de erro (`@idle_period.errors`)
5. [x] rota `DELETE /idle_periods/:id` remove o registro **apenas se pertencer ao `Current.user`** (multi-tenant defense in depth — filtro explícito por `user_id`, não apenas `find`)
6. [x] destroy bem-sucedido responde `turbo_stream` removendo o item (lista/totalizadores completos ficam para Story 13.3/13.4)
7. [x] tentativa de acessar/destruir `IdlePeriod` de outro usuário retorna **404** (não 403) — mesmo padrão de Task/TaskItem cross-tenant

**Given** que o controller está implementado

**When** analiso o código

**Then**
8. [x] controller inclui `before_action :require_authentication`
9. [x] `idle_period_params` faz strong params permitindo apenas `:start_time, :end_time, :work_date` — **nunca `:user_id`**
10. [x] criação usa `Current.user.idle_periods.build(idle_period_params)` (nunca `IdlePeriod.new` com user_id manual)

## Tasks / Subtasks

- [x] Adicionar rotas em `config/routes.rb`
  - [x] `resources :idle_periods, only: [ :new, :create, :destroy ]` (fora do nested de tasks — IdlePeriod não pertence a Task)

- [x] Criar `IdlePeriodsController` (`app/controllers/idle_periods_controller.rb`)
  - [x] `before_action :require_authentication`
  - [x] `before_action :set_idle_period, only: [ :destroy ]`
  - [x] Action `new` — instancia `@idle_period = Current.user.idle_periods.build(work_date: Date.current)`
  - [x] Action `create` — `Current.user.idle_periods.build(idle_period_params)`, salva, responde turbo_stream
  - [x] Action `destroy` — `@idle_period.destroy`, responde turbo_stream
  - [x] Método privado `set_idle_period` — `Current.user.idle_periods.find(params[:id])` (scoping garante 404 cross-tenant)
  - [x] Método privado `idle_period_params` — `params.require(:idle_period).permit(:start_time, :end_time, :work_date)`

- [x] Criar views/partials
  - [x] `app/views/idle_periods/new.html.erb` — Turbo Frame `#modal` com formulário (padrão de `task_items/modal_form`)
  - [x] `app/views/idle_periods/_modal_form.html.erb` — formulário reaproveitável em erro de validação
  - [x] Stream inline no controller — fecha modal em `create` (KPI de totalizadores é da Story 13.3, ainda não existe)

- [x] Adicionar botão/link de acesso no dashboard
  - [x] Botão "Registrar período sem tarefa" na view do dashboard, abrindo `idle_periods/new` no Turbo Frame `#modal` (padrão de "Nova Tarefa" — ver Story 5.8)

## Dev Notes

### EPIC CONTEXT: Epic 13 — Disponibilidade sem Tarefa (DM-012)

Esta é a **segunda story** do epic — depende de `IdlePeriod` (Story 13.1) já existir. Segue o padrão estrutural de `TaskItemsController`, mas **sem nesting em Task** (IdlePeriod não pertence a Task/Company/Project).

### Previous Story Intelligence (Story 13.1)

- Model `IdlePeriod` tem `belongs_to :user`, `attr_readonly :user_id`, callback `before_save :calculate_hours`
- Validações: presence de `start_time`, `end_time`, `work_date`; customizada `end_time_after_start_time`
- Scope disponível: `by_user_and_month(user, date)`
- **Não** há associação com Task/Company/Project — controller não precisa (nem deve) fazer nested resource

### Architecture Compliance

**Multi-tenancy — Defense in Depth (OBRIGATÓRIO, ver architecture.md §3 e DA-003):**
```ruby
class IdlePeriodsController < ApplicationController
  before_action :require_authentication
  before_action :set_idle_period, only: [ :destroy ]

  def new
    @idle_period = Current.user.idle_periods.build(work_date: Date.current)
  end

  def create
    @idle_period = Current.user.idle_periods.build(idle_period_params)
    # ...
  end

  private

  def set_idle_period
    # Scoping via Current.user garante 404 (não 403) em cross-tenant —
    # mesmo padrão de TaskItemsController#set_task_item
    @idle_period = Current.user.idle_periods.find(params[:id])
  end

  def idle_period_params
    params.require(:idle_period).permit(:start_time, :end_time, :work_date) # SEM :user_id
  end
end
```

Este é o mesmo padrão de `TaskItemsController` (ver `app/controllers/task_items_controller.rb#set_task_item`): scoping explícito por tenant antes do `find`, nunca `IdlePeriod.find(params[:id])` puro.

**Padrão de rotas — reaproveitar `resources`, não nested (diferente de TaskItem):**
```ruby
# config/routes.rb
resources :idle_periods, only: [ :new, :create, :destroy ]
```
TaskItem é nested em `tasks` porque pertence a uma Task. IdlePeriod é uma entidade de topo, sem pai — rota direta.

**Padrão de resposta Turbo Stream (seguir estrutura de `TaskItemsController#create`, mas sem os KPIs específicos de Task):**
```ruby
def create
  @idle_period = Current.user.idle_periods.build(idle_period_params)

  if @idle_period.save
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.action(:remove, "modal"), # fecha o modal
          turbo_stream.replace("kpi-horas-sem-tarefa", partial: "dashboard/idle_hours", locals: { idle_hours: calculate_idle_hours_period }) # Story 13.3
        ]
      end
      format.html { redirect_to root_path, notice: "Período sem tarefa registrado" }
    end
  else
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "modal",
          partial: "idle_periods/modal_form",
          locals: { idle_period: @idle_period }
        )
      end
      format.html { redirect_to root_path, alert: @idle_period.errors.full_messages.to_sentence }
    end
  end
end
```

**NOTA:** o partial `dashboard/idle_hours` e o método `calculate_idle_hours_period` são entregues na **Story 13.3** — nesta story (13.2), o `create`/`destroy` devem responder turbo_stream fechando o modal; a integração completa com o KPI acontece quando 13.3 for implementada. Se 13.3 ainda não existir no momento da implementação de 13.2, criar o stream apenas com o fechamento do modal e adicionar o `turbo_stream.replace` do KPI depois (ou implementar em conjunto, já que ambas fazem parte do mesmo epic pequeno).

**Padrão de modal Turbo Frame (arquitetura.md §5, seguir padrão exato de acessibilidade):**
```erb
<turbo-frame id="modal">
  <div role="dialog" aria-modal="true" data-controller="modal"
       data-action="keydown.escape@window->modal#close click->modal#closeOnOverlayClick">
    <%= form_with model: @idle_period, url: idle_periods_path do |f| %>
      <%= f.time_field :start_time %>
      <%= f.time_field :end_time %>
      <%= f.date_field :work_date %>
      <%= f.submit "Registrar" %>
    <% end %>
  </div>
</turbo-frame>
```

### File Structure Requirements

- Controller: `app/controllers/idle_periods_controller.rb`
- Views: `app/views/idle_periods/new.html.erb`, `app/views/idle_periods/_modal_form.html.erb`
- Routes: adicionar em `config/routes.rb` (fora do bloco `resources :tasks`)

### Testing Requirements

Specs completos (controller spec, request spec) são escopo da **Story 13.4**. Ainda assim, ao implementar, validar manualmente:
- Criação bem-sucedida fecha modal e persiste registro vinculado ao `Current.user`
- Tentativa de destroy de `IdlePeriod` de outro user retorna 404
- Erro de validação re-renderiza modal com mensagens

### Potential Pitfalls & Prevention

**1. Permitir `:user_id` em strong params:**
❌ ERRADO: `params.require(:idle_period).permit(:start_time, :end_time, :work_date, :user_id)`
✅ CORRETO: nunca incluir `:user_id` — regra absoluta do projeto (ver DA-003, architecture.md §3)

**2. Usar `IdlePeriod.find(params[:id])` sem scoping:**
❌ ERRADO: `@idle_period = IdlePeriod.find(params[:id])` (vaza cross-tenant, 403 em vez de 404, ou pior: destrói registro de outro user)
✅ CORRETO: `@idle_period = Current.user.idle_periods.find(params[:id])`

**3. Nesting em `tasks` como TaskItem:**
❌ ERRADO: `resources :tasks do resources :idle_periods end`
✅ CORRETO: `resources :idle_periods, only: [ :new, :create, :destroy ]` — IdlePeriod não pertence a Task

**4. Retornar 403 em vez de 404 em cross-tenant:**
O padrão do projeto é 404 sempre (não vazar existência de IDs) — `find` com scoping já gera isso naturalmente via `ActiveRecord::RecordNotFound`.

### References

**Architecture Decisions:**
- [architecture.md §4 — Arquitetura de controllers](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md) — `IdlePeriodsController` já documentado como item planejado
- [architecture.md §6 — DA-100, DA-101, DA-102](/home/igor/rails_app/cronos-poc/_bmad-output/planning-artifacts/architecture.md)

**Referência de implementação (padrão a seguir):**
- [app/controllers/task_items_controller.rb](/home/igor/rails_app/cronos-poc/app/controllers/task_items_controller.rb) — estrutura de controller com turbo_stream, scoping multi-tenant
- [app/controllers/concerns/tenant_scoped.rb](/home/igor/rails_app/cronos-poc/app/controllers/concerns/tenant_scoped.rb) — padrão `scoped_*`

**Previous Story:**
- [001-model-idleperiod-migration.md](/home/igor/rails_app/cronos-poc/_bmad-output/implementation-artifacts/DM-012-registro-disponibilidade-sem-tarefa/001-model-idleperiod-migration.md)

### Definition of Done

- [x] Rotas `new`, `create`, `destroy` funcionando
- [x] `IdlePeriodsController` criado seguindo padrão de scoping multi-tenant
- [x] Strong params sem `:user_id`
- [x] Cross-tenant destroy retorna 404
- [x] Modal abre/fecha via Turbo Frame + Turbo Stream
- [x] Erro de validação re-renderiza modal com mensagens
- [x] Rubocop sem ofensas

## Dev Agent Record

### Agent Model Used
Claude Sonnet 5 (bmad-agent-dev / Amelia)

### Debug Log References
- `docker exec -e RAILS_ENV=test cronos-poc-web-1 bundle exec rspec` — 1167 examples, 0 failures, 100.0% line coverage
- `docker exec cronos-poc-web-1 bundle exec rubocop app/controllers/idle_periods_controller.rb config/routes.rb` — 2 files inspected, no offenses detected

### Completion Notes List
- Controller segue exatamente o padrão de scoping multi-tenant de `TaskItemsController#set_task_item`: `Current.user.idle_periods.find(params[:id])` gera 404 (via `rescue_from ActiveRecord::RecordNotFound` já existente em `ApplicationController`) em vez de 403 em cross-tenant.
- Strong params (`idle_period_params`) permitem apenas `:start_time, :end_time, :work_date` — sem `:user_id`; testado explicitamente (param `user_id` malicioso é ignorado, registro fica com `Current.user`).
- Stream de `create` fecha o modal (`turbo_stream.action(:remove, "modal")`); o `turbo_stream.replace` do KPI `kpi-horas-sem-tarefa` é adiado para a Story 13.3, conforme nota da própria story (KPI e helper `calculate_idle_hours_period` ainda não existem).
- Stream de `destroy` remove `idle_period_#{id}` da lista (id previsto para o partial de item que será usado pela Story 13.3/13.4, já que 13.2 não inclui lista de itens na UI ainda).
- Botão "Registrar período sem tarefa" adicionado ao dashboard ao lado de "Nova Tarefa" e "Resumo Diário", abrindo `idle_periods/new` no Turbo Frame `#modal` (mesmo padrão de `new_task_path`).
- Specs completos (controller spec) foram antecipados nesta story para atender ao requisito de 100% de cobertura do projeto (SimpleCov enforce), embora a story architecture-doc atribua "specs completos" formalmente à Story 13.4. Cobrem: autenticação, criação escopada ao Current.user, strong params sem user_id, turbo_stream de sucesso/erro, destroy e 404 cross-tenant.

### File List
- `config/routes.rb` (modificado)
- `app/controllers/idle_periods_controller.rb` (novo)
- `app/views/idle_periods/new.html.erb` (novo)
- `app/views/idle_periods/_modal_form.html.erb` (novo)
- `app/views/dashboard/index.html.erb` (modificado)
- `spec/controllers/idle_periods_controller_spec.rb` (novo)

### QA Findings Aplicados
- **HIGH:** `destroy` não checava o retorno de `@idle_period.destroy` antes de responder sucesso. Corrigido para `if @idle_period.destroy ... else format.turbo_stream { head :unprocessable_content } ...` (padrão de `TaskItemsController#destroy`). Cobertura de testes adicionada (`when destroy fails`).
- Suite completa após correção: 1169 examples, 0 failures, 100.0% line coverage. Rubocop sem ofensas.

### Validação Manual (Playwright MCP)
- Login em `http://localhost:3001` como `admin@cronos-poc.local`.
- Clique em "Registrar período sem tarefa" no dashboard abre modal via Turbo Frame `#modal` (AC1) — screenshot em `.playwright-mcp/002-idleperiodscontroller-validation.png`.
- Submissão com `start_time: 08:00`, `end_time: 09:00` cria o registro e fecha o modal automaticamente via turbo_stream, sem reload de página (AC2, AC3). Registro de teste removido após validação via `rails runner`.
- Submissão com `end_time` anterior a `start_time` re-renderiza o modal preservando valores e exibindo mensagem de erro em `role="alert"` (AC4). Nota: atributo aparece em inglês ("End time") — i18n pré-existente do projeto, registrado em memória, fora do escopo desta story.
- Cross-tenant 404 e strong params validados via `spec/controllers/idle_periods_controller_spec.rb` (specs automatizados, ACs 5, 7, 9).
