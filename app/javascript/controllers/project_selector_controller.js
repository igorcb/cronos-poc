import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["companySelect", "projectSelect"]

  // Store loaded projects for validation
  loadedProjects = []

  connect() {
    // Controller initialized
  }

  async loadProjects() {
    const companyId = this.companySelectTarget.value

    // Clear and disable project select
    this.projectSelectTarget.innerHTML = '<option value="">Carregando...</option>'
    this.projectSelectTarget.disabled = true
    this.loadedProjects = []

    if (!companyId) {
      this.projectSelectTarget.innerHTML = '<option value="">Selecione uma empresa primeiro</option>'
      return
    }

    try {
      const response = await fetch(`/tasks/projects?company_id=${companyId}`, {
        headers: {
          "Accept": "application/json"
        }
      })

      if (!response.ok) {
        throw new Error("Failed to load projects")
      }

      const projects = await response.json()
      this.loadedProjects = projects

      // Clear existing options
      this.projectSelectTarget.innerHTML = '<option value="">Selecione um projeto</option>'

      // Add new options
      projects.forEach(project => {
        const option = document.createElement("option")
        option.value = project.id
        option.textContent = project.name
        option.dataset.companyId = companyId  // Store company_id for validation
        this.projectSelectTarget.appendChild(option)
      })

      // Enable select if there are projects
      this.projectSelectTarget.disabled = projects.length === 0

      // Update hint text
      const hint = document.getElementById('project-hint')
      if (hint) {
        hint.textContent = `${projects.length} projeto(s) disponível(is)`
      }
    } catch (error) {
      console.error("Error loading projects:", error)
      this.projectSelectTarget.innerHTML = '<option value="">Erro ao carregar projetos</option>'

      const hint = document.getElementById('project-hint')
      if (hint) {
        hint.textContent = 'Erro ao carregar projetos'
      }
    }
  }

  validateBeforeSubmit(event) {
    const selectedCompanyId = this.companySelectTarget.value
    const selectedProjectId = this.projectSelectTarget.value

    if (!selectedProjectId) {
      event.preventDefault()
      alert('Por favor, selecione um projeto')
      return false
    }

    // Validate that selected project belongs to selected company
    const selectedOption = this.projectSelectTarget.querySelector(`option[value="${selectedProjectId}"]`)
    if (selectedOption && selectedOption.dataset.companyId !== selectedCompanyId) {
      event.preventDefault()
      alert('O projeto selecionado não pertence à empresa escolhida. Por favor, selecione novamente.')
      this.loadProjects()  // Reload projects to reset
      return false
    }

    return true
  }
}
