# Story 6.1: Implementar Filtros por Empresa e Projeto

Status: ready-for-dev

## Story

**Como** Igor,
**Quero** filtrar entradas por empresa ou projeto,
**Para que** eu veja apenas dados relevantes.

## Acceptance Criteria

1. Formulário de filtros possui: company_id (select), project_id (select)
2. Dropdowns têm opção "Todas" como padrão
3. Ao selecionar empresa, index filtra: `where(company_id: params[:company_id])`
4. Ao selecionar projeto, index filtra: `where(project_id: params[:project_id])`
5. Filtros aplicam em < 1 segundo (NFR4)
6. URL reflete filtros: `/time_entries?company_id=1&project_id=2`

## Dev Notes

```ruby
# app/controllers/time_entries_controller.rb
def index
  @time_entries = TimeEntry.includes(:company, :project).where(user: current_user)

  @time_entries = @time_entries.where(company_id: params[:company_id]) if params[:company_id].present?
  @time_entries = @time_entries.where(project_id: params[:project_id]) if params[:project_id].present?

  @time_entries = @time_entries.order(date: :desc)
end
```
