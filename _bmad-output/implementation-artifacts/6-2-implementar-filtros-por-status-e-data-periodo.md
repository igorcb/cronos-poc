# Story 6.2: Implementar Filtros por Status e Data/Período

Status: ready-for-dev

## Story

**Como** Igor,
**Quero** filtrar por status e períodos de tempo,
**Para que** eu analise dados históricos.

## Acceptance Criteria

1. Status dropdown possui: "Todos", "Pendente", "Finalizado", "Reaberto", "Entregue"
2. Filtro de data permite range: `where(date: params[:date_from]..params[:date_to])`
3. Filtros são combinados com AND lógico
4. Ao aplicar múltiplos filtros, query permanece otimizada
5. Filtros aplicam instantaneamente (< 1s)

## Dev Notes

```ruby
def index
  @time_entries = TimeEntry.includes(:company, :project).where(user: current_user)

  @time_entries = @time_entries.where(status: params[:status]) if params[:status].present?
  @time_entries = @time_entries.where(date: params[:date_from]..params[:date_to]) if params[:date_from].present?

  @time_entries = @time_entries.order(date: :desc)
end
```
