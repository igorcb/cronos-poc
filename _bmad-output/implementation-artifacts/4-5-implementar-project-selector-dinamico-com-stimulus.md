# Story 4.5: Implementar Project Selector Dinâmico com Stimulus

Status: ready-for-dev

## Story

**Como** Igor,
**Quero** que projetos sejam filtrados pela empresa selecionada,
**Para que** eu não veja projetos de outras empresas.

## Acceptance Criteria

1. Ao selecionar empresa no dropdown
2. Dropdown de projetos atualiza via fetch para `/projects?company_id=X`
3. Apenas projetos daquela empresa aparecem
4. Se mudar empresa, lista de projetos atualiza novamente
5. Endpoint `/projects.json?company_id=X` retorna JSON de projetos
6. Interação é instantânea (< 300ms)

## Dev Notes

```javascript
// app/javascript/controllers/project_selector_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["companySelect", "projectSelect"]

  async updateProjects() {
    const companyId = this.companySelectTarget.value

    if (!companyId) {
      this.projectSelectTarget.innerHTML = '<option value="">Selecione um projeto</option>'
      return
    }

    const response = await fetch(`/projects.json?company_id=${companyId}`)
    const projects = await response.json()

    this.projectSelectTarget.innerHTML = '<option value="">Selecione um projeto</option>'
    projects.forEach(project => {
      const option = document.createElement('option')
      option.value = project.id
      option.textContent = project.name
      this.projectSelectTarget.appendChild(option)
    })
  }
}
```

```ruby
# app/controllers/projects_controller.rb
def index
  @projects = if params[:company_id].present?
                Project.where(company_id: params[:company_id]).order(:name)
              else
                Project.includes(:company).order(created_at: :desc)
              end

  respond_to do |format|
    format.html
    format.json { render json: @projects.select(:id, :name) }
  end
end
```
