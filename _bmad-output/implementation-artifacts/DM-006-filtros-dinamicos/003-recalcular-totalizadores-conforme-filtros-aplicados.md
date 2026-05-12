# Story 6.3: Recalcular Totalizadores Conforme Filtros Aplicados

Status: done

## Story

**Como** Igor,
**Quero** que totalizadores reflitam apenas entradas filtradas,
**Para que** análises sejam precisas.

## Acceptance Criteria

1. Ao aplicar qualquer filtro, totalizadores recalculam baseados nas entradas filtradas
2. "Total geral" exibe soma apenas das entradas visíveis
3. "Total por empresa" agrupa apenas entradas filtradas
4. Recalculo é instantâneo (< 500ms)
5. Mensagem indica: "Mostrando X entradas (filtrado)"

## Dev Agent Record

### Implementation Notes (2026-04-03)

**Amelia — Senior Software Engineer**

**AC1-AC4:** O controller já calculava totalizadores passando `@tasks` filtrado para `calculate_daily_total(@tasks)` e `calculate_company_totals(@tasks)`. Confirmado que a lógica estava correta.

**AC5:** Adicionado `@filtered_count` e `@is_filtered` no `TasksController#index`. View `index.html.erb` exibe div `#filter_count_message` com "Mostrando X entradas (filtrado)" quando `@is_filtered == true`.

**Testes:** 14 novos exemplos no contexto `Story 6.3` em `spec/controllers/tasks_controller_spec.rb`, cobrindo AC1-AC5. 77/77 passando. Falhas pré-existentes (109) em specs de request/feature não relacionadas.

### File List
- `app/controllers/tasks_controller.rb` — Adicionado `@filtered_count` e `@is_filtered`
- `app/views/tasks/index.html.erb` — Adicionado bloco condicional com mensagem de contagem (AC5)
- `spec/controllers/tasks_controller_spec.rb` — 14 novos exemplos cobrindo AC1-AC5

### Change Log
- 2026-04-06: QA fixes — @is_filtered usa company_id&.positive?; @period_label dinâmico; 7 novos specs (84 total)
- 2026-04-03: Implementação Story 6.3 — totalizadores recalculam por filtro + mensagem de contagem

## Dev Notes

```ruby
def index
  @time_entries = apply_filters(TimeEntry.includes(:company, :project).where(user: current_user))

  @total_hours = @time_entries.sum(:duration_minutes) / 60.0
  @total_value = @time_entries.sum(:calculated_value)
end

private

def apply_filters(scope)
  scope = scope.where(company_id: params[:company_id]) if params[:company_id].present?
  scope = scope.where(project_id: params[:project_id]) if params[:project_id].present?
  scope = scope.where(status: params[:status]) if params[:status].present?
  scope = scope.where(date: params[:date_from]..params[:date_to]) if params[:date_from].present?
  scope
end
```
