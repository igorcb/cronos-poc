import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    // Se markup veio com painéis sem hidden (cenário de erros server-side),
    // não força tab inicial — mantém todos visíveis para que o usuário veja os erros.
    const anyPanelVisible = this.panelTargets.slice(1).some(p => !p.hasAttribute("hidden"))
    if (anyPanelVisible) return
    this.show(0)
  }

  select(event) {
    event.preventDefault()
    const index = this.tabTargets.indexOf(event.currentTarget)
    if (index >= 0) this.show(index)
  }

  show(index) {
    this.tabTargets.forEach((tab, i) => {
      const active = i === index
      tab.setAttribute("aria-selected", active ? "true" : "false")
      tab.setAttribute("tabindex", active ? "0" : "-1")
      tab.classList.toggle("border-blue-500", active)
      tab.classList.toggle("text-blue-300", active)
      tab.classList.toggle("border-transparent", !active)
      tab.classList.toggle("text-gray-400", !active)
    })

    this.panelTargets.forEach((panel, i) => {
      panel.toggleAttribute("hidden", i !== index)
    })
  }

  keydown(event) {
    const current = this.tabTargets.indexOf(event.currentTarget)
    if (current < 0) return

    let next = null
    if (event.key === "ArrowRight") next = (current + 1) % this.tabTargets.length
    else if (event.key === "ArrowLeft") next = (current - 1 + this.tabTargets.length) % this.tabTargets.length
    else if (event.key === "Home") next = 0
    else if (event.key === "End") next = this.tabTargets.length - 1

    if (next !== null) {
      event.preventDefault()
      this.show(next)
      this.tabTargets[next].focus()
    }
  }
}
