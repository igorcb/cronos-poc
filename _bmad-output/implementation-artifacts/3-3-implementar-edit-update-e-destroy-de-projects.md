# Story 3.3: Implementar Edit/Update e Destroy de Projects

Status: ready-for-dev

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

- [ ] Adicionar actions edit, update, destroy
- [ ] Criar view edit.html.erb
- [ ] Implementar lógica de destroy com dependent: :restrict_with_error
- [ ] Adicionar links "Editar" e "Deletar" no index
- [ ] Testar fluxo completo

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

- [ ] `dependent: :restrict_with_error` bloqueia deleção se houver time_entries
- [ ] Rescue de ActiveRecord::DeleteRestrictionError implementado
