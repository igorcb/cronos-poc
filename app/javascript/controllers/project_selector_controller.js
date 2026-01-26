import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["companySelect", "projectSelect"]

  connect() {
    // Stimulus actions handle events via data-action in the view
    // No manual addEventListener needed - prevents duplicate events
  }

  loadProjects() {
    const companyId = this.companySelectTarget.value

    // Build URL based on whether company is selected
    const url = companyId
      ? `/projects.json?company_id=${companyId}`
      : `/projects.json`

    // Disable project select during loading
    this.projectSelectTarget.disabled = true

    fetch(url)
      .then(response => {
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}: ${response.statusText}`)
        }
        return response.json()
      })
      .then(projects => {
        this.populateProjectSelect(projects)
      })
      .catch(error => {
        console.error("Error loading projects:", error)
        // Show user-friendly error feedback
        this.projectSelectTarget.innerHTML = ""
        const errorOption = document.createElement("option")
        errorOption.value = ""
        errorOption.textContent = "Erro ao carregar projetos"
        this.projectSelectTarget.appendChild(errorOption)
      })
      .finally(() => {
        this.projectSelectTarget.disabled = false
      })
  }

  populateProjectSelect(projects) {
    // Clear existing options
    this.projectSelectTarget.innerHTML = ""

    // Add default option
    const defaultOption = document.createElement("option")
    defaultOption.value = ""
    defaultOption.textContent = "Selecione um projeto"
    this.projectSelectTarget.appendChild(defaultOption)

    // Add project options
    projects.forEach(project => {
      const option = document.createElement("option")
      option.value = project.id
      option.textContent = project.name
      this.projectSelectTarget.appendChild(option)
    })
  }
}
