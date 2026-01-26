import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["companySelect", "projectSelect"]
  static values = { companyId: String }

  connect() {
    if (this.hasCompanySelectTarget) {
      this.companySelectTarget.addEventListener("change", () => this.loadProjects())
    }
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
      .then(response => response.json())
      .then(projects => {
        this.populateProjectSelect(projects)
      })
      .catch(error => {
        console.error("Error loading projects:", error)
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
