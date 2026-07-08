# Story 13.2: IdlePeriodsController

Status: ready-for-dev

<!-- Ultimate context engine analysis completed - comprehensive developer guide created -->

## Story

**Como** usuário do Cronos,

**Quero** registrar (criar) e remover períodos "Sem Tarefa" através de um modal no dashboard,

**Para que** eu consiga marcar rapidamente início/fim de disponibilidade ociosa sem sair do fluxo normal de uso.

## Acceptance Criteria

**Given** que o model `IdlePeriod` existe (Story 13.1)

**When** acesso a rota de criação de período sem tarefa

**Then**
1. rota `GET /idle_periods/new` renderiza modal Turbo Frame (`#modal`) com formulário de `start_time`, `end_time`, `work_date`
2. rota `POST /idle_periods` cria o registro escopado ao `Current.user` (nunca aceita `user_id` de params)
3. em sucesso, resposta `turbo_stream` fecha o modal e atualiza os totalizadores relevantes do dashboard
4. em falha de validação, resposta `turbo_stream` re-renderiza o modal com mensagens de erro (`@idle_period.errors`)
5. rota `DELETE /idle_periods/:id` remove o registro **apenas se pertencer ao `Current.user`** (multi-tenant defense in depth — filtro explícito por `user_id`, não apenas `find`)
6. destroy bem-sucedido responde `turbo_stream` removendo o item da lista e atualizando totalizadores
7. tentativa de acessar/destruir `IdlePeriod` de outro usuário retorna **404** (não 403) — mesmo padrão de Task/TaskItem cross-tenant

**Given** que o controller está implementado

**When** analiso o código

**Then**
8. controller inclui `before_action :require_authentication`
9. `idle_period_params` faz strong params permitindo apenas `:start_time, :end_time, :work_date` — **nunca `:user_id`**
10. criação usa `Current.user.idle_periods.build(idle_period_params)` (nunca `IdlePeriod.new` com user_id manual)

## Tasks / Subtasks

- [ ] Adicionar rotas em `config/routes.rb`
  - [ ] `resources :idle_periods, only: [ :new, :create, :destroy ]` (fora do nested de tasks — IdlePeriod não pertence a Task)

- [ ] Criar `IdlePeriodsController` (`app/controllers/idle_periods_controller.rb`)
  - [ ] `before_action :require_authentication`
  - [ ] `before_action :set_idle_period, only: [ :destroy ]`
  - [ ] Action `new` — instancia `@idle_period = Current.user.idle_periods.build(work_date: Date.current)`
  - [ ] Action `create` — `Current.user.idle_periods.build(idle_period_params)`, salva, responde turbo_stream
  - [ ] Action `destroy` — `@idle_period.destroy`, responde turbo_stream
  - [ ] Método privado `set_idle_period` — `Current.user.idle_periods.find(params[:id])` (scoping garante 404 cross-tenant)
  - [ ] Método privado `idle_period_params` — `params.require(:idle_period).permit(:start_time, :end_time, :work_date)`

- [ ] Criar views/partials
  - [ ] `app/views/idle_periods/new.html.erb` — Turbo Frame `#modal` com formulário (padrão de `task_items/modal_form`)
  - [ ] `app/views/idle_periods/_modal_form.html.erb` — formulário reaproveitável em erro de validação
  - [ ] `app/views/idle_periods/create.turbo_stream.erb` ou stream inline no controller — fechar modal + atualizar totalizadores

- [ ] Adicionar botão/link de acesso no dashboard
  - [ ] Botão "Registrar período sem tarefa" na view do dashboard, abrindo `idle_periods/new` no Turbo Frame `#modal` (padrão de "Nova Tarefa" — ver Story 5.8)

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
- [13-1-model-idleperiod-migration.md](/home/igor/rails_app/cronos-poc/_bmad-output/implementation-artifacts/DM-012-registro-disponibilidade-sem-tarefa/13-1-model-idleperiod-migration.md)

### Definition of Done

- [ ] Rotas `new`, `create`, `destroy` funcionando
- [ ] `IdlePeriodsController` criado seguindo padrão de scoping multi-tenant
- [ ] Strong params sem `:user_id`
- [ ] Cross-tenant destroy retorna 404
- [ ] Modal abre/fecha via Turbo Frame + Turbo Stream
- [ ] Erro de validação re-renderiza modal com mensagens
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
