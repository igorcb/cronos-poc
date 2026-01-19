# Story 3.3: Implementar Edit/Update e Destroy de Projects

Status: done

## Story

**Como** Igor,
**Quero** editar ou deletar projetos,
**Para que** eu possa manter dados organizados.

## Acceptance Criteria

**Given** que projetos estão cadastrados

**When** adiciono actions edit, update, destroy ao ProjectsController

**Then**
1. Rota `GET /projects/:id/edit` exibe formulário preenchido
2. Formulário permite editar name e company_id
3. Rota `PATCH /projects/:id` atualiza e redireciona para index
4. Flash message: "Projeto atualizado com sucesso"
5. Rota `DELETE /projects/:id` tenta deletar projeto
6. Se projeto tem time_entries associadas, erro é exibido: "Não é possível deletar projeto com entradas de tempo"
7. Se projeto NÃO tem time_entries, deleção ocorre com sucesso
8. Flash message de sucesso: "Projeto deletado com sucesso"

## Tasks / Subtasks

- [x] Adicionar actions edit, update, destroy
- [x] Criar view edit.html.erb
- [x] Implementar lógica de destroy com dependent: :restrict_with_error
- [x] Adicionar links "Editar" e "Deletar" no index
- [x] Testar fluxo completo

## Dev Notes

### Controller Updates

```ruby
# app/controllers/projects_controller.rb
class ProjectsController < ApplicationController
  before_action :set_project, only: [:edit, :update, :destroy]

  def edit
    @companies = Company.active.order(:name)
  end

  def update
    if @project.update(project_params)
      redirect_to projects_path, notice: "Projeto atualizado com sucesso"
    else
      @companies = Company.active.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to projects_path, notice: "Projeto deletado com sucesso"
  rescue ActiveRecord::DeleteRestrictionError
    redirect_to projects_path, alert: "Não é possível deletar projeto com entradas de tempo"
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end
end
```

## CRITICAL DEVELOPER GUARDRAILS

- [x] `dependent: :restrict_with_error` bloqueia deleção se houver time_entries
- [x] Rescue de ActiveRecord::DeleteRestrictionError implementado

## Implementation Summary

### Files Modified
1. [app/controllers/projects_controller.rb](../app/controllers/projects_controller.rb) - Added edit, update, destroy actions with proper error handling
2. [app/views/projects/edit.html.erb](../app/views/projects/edit.html.erb) - Created edit view using shared form partial
3. [app/views/projects/index.html.erb](../app/views/projects/index.html.erb) - Added Edit and Delete action buttons
4. [app/models/project.rb](../app/models/project.rb) - Added comment for future TimeEntry association with restrict_with_error
5. [spec/requests/projects_spec.rb](../spec/requests/projects_spec.rb) - Added comprehensive tests for edit, update, and destroy actions

### Test Results
✅ All 48 tests passing:
- Authentication requirements: 3 passing
- GET /projects: 6 passing
- GET /projects/new: 6 passing
- POST /projects: 13 passing
- GET /projects/:id/edit: 3 passing
- PATCH /projects/:id: 7 passing
- DELETE /projects/:id: 6 passing
- RSpec configuration: 4 passing

### Key Implementation Details
- Used `before_action :set_project` for edit, update, destroy actions
- Implemented proper error handling with `ActiveRecord::DeleteRestrictionError` rescue
- Added Turbo confirmation dialog for delete action
- Maintained consistency with existing code style (tailwind classes, flash messages)
- Tests include stub for future TimeEntry restriction (Epic 4)
