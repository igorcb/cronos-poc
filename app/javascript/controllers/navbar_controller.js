import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "menuIcon", "closeIcon", "toggleButton"]

  toggle() {
    const isHidden = this.menuTarget.classList.contains("hidden")
    this.menuTarget.classList.toggle("hidden")
    this.menuIconTarget.classList.toggle("hidden")
    this.closeIconTarget.classList.toggle("hidden")
    if (this.hasToggleButtonTarget) {
      this.toggleButtonTarget.setAttribute("aria-expanded", isHidden ? "true" : "false")
      this.toggleButtonTarget.setAttribute("aria-label", isHidden ? "Fechar menu de navegação" : "Abrir menu de navegação")
    }
  }

  close() {
    if (!this.menuTarget.classList.contains("hidden")) {
      this.menuTarget.classList.add("hidden")
      this.menuIconTarget.classList.remove("hidden")
      this.closeIconTarget.classList.add("hidden")
      if (this.hasToggleButtonTarget) {
        this.toggleButtonTarget.setAttribute("aria-expanded", "false")
        this.toggleButtonTarget.setAttribute("aria-label", "Abrir menu de navegação")
      }
    }
  }
}
