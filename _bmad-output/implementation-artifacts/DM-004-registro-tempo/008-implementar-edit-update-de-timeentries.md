# Story 7.1: Implementar Edit/Update de TimeEntries

Status: ready-for-dev

## Story

**Como** Igor,
**Quero** editar entradas existentes,
**Para que** eu possa corrigir erros.

## Acceptance Criteria

1. Rota `GET /time_entries/:id/edit` exibe formulário preenchido
2. Formulário permite editar todos os campos: date, times, company, project, activity, status
3. Validações tripla camada aplicam na edição
4. Ao salvar, cálculos são refeitos via Calculable concern
5. Rota `PATCH /time_entries/:id` atualiza entrada
6. Flash message: "Entrada atualizada com sucesso"
7. Totalizadores recalculam automaticamente via Turbo Stream
8. Edição preserva integridade referencial

## Dev Notes

```ruby
def edit
  @time_entry = TimeEntry.find(params[:id])
  @companies = Company.active.order(:name)
  @projects = @time_entry.company.projects.order(:name)
end

def update
  @time_entry = TimeEntry.find(params[:id])

  if @time_entry.update(time_entry_params)
    redirect_to time_entries_path, notice: "Entrada atualizada com sucesso"
  else
    @companies = Company.active.order(:name)
    @projects = @time_entry.company.projects.order(:name)
    render :edit, status: :unprocessable_entity
  end
end
```
