# Story 4.4: Implementar CRUD de TimeEntries (New/Create)

Status: ready-for-dev

## Story

**Como** Igor,
**Quero** registrar novas entradas de tempo rapidamente,
**Para que** eu possa fazer em ~30 segundos.

## Acceptance Criteria

1. Rota `GET /time_entries/new` exibe formulário
2. Formulário possui: date (date picker, default: today), start_time, end_time (time fields)
3. Formulário possui: company_id (select), project_id (select), activity (textarea), status (select)
4. Dropdown de companies mostra apenas `Company.active`
5. Dropdown de projects é filtrado por company selecionada (Stimulus)
6. Rota `POST /time_entries` cria entrada
7. Campo hourly_rate é copiado de company.hourly_rate automaticamente
8. Cálculos são executados via Calculable concern
9. Flash message: "Entrada registrada com sucesso"
10. Tempo médio de registro < 30 segundos

## Dev Notes

```ruby
# app/controllers/time_entries_controller.rb
class TimeEntriesController < ApplicationController
  before_action :require_authentication

  def new
    @time_entry = TimeEntry.new(date: Date.today, status: 'pending')
    @companies = Company.active.order(:name)
    @projects = []
  end

  def create
    @time_entry = TimeEntry.new(time_entry_params)
    @time_entry.user = current_user
    @time_entry.hourly_rate = @time_entry.company.hourly_rate

    if @time_entry.save
      redirect_to time_entries_path, notice: "Entrada registrada com sucesso"
    else
      @companies = Company.active.order(:name)
      @projects = Project.where(company_id: @time_entry.company_id)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def time_entry_params
    params.require(:time_entry).permit(:date, :start_time, :end_time, :company_id, :project_id, :activity, :status)
  end
end
```
