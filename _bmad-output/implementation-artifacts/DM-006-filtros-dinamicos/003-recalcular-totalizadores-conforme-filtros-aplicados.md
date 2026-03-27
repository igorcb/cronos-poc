# Story 6.3: Recalcular Totalizadores Conforme Filtros Aplicados

Status: ready-for-dev

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
