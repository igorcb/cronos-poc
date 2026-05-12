import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this._submitHandler = (event) => this.submit(event)
    this.element.addEventListener("submit", this._submitHandler, { capture: true })
  }

  disconnect() {
    this.element.removeEventListener("submit", this._submitHandler, { capture: true })
  }

  submit(event) {
    const required = this.element.querySelectorAll("[aria-required='true']")
    let firstInvalid = null

    required.forEach(field => {
      if (!field.value || field.value.trim() === "") {
        this._showError(field)
        if (!firstInvalid) firstInvalid = field
      }
    })

    if (firstInvalid) {
      event.preventDefault()
      firstInvalid.focus()
    }
  }

  clearError(event) {
    const field = event.target
    if (field.value && field.value.trim() !== "") {
      field.classList.remove("border-red-500")
      field.classList.add("border-gray-600")
      field.removeAttribute("aria-invalid")
      const errorId = field.getAttribute("data-error-id")
      if (errorId) {
        document.getElementById(errorId)?.remove()
        field.removeAttribute("data-error-id")
      }
    }
  }

  _showError(field) {
    field.classList.add("border-red-500")
    field.classList.remove("border-gray-600")
    field.setAttribute("aria-invalid", "true")

    const errorId = `js_error_${field.id || field.name.replace(/[\[\]]/g, "_")}`
    if (document.getElementById(errorId)) return

    field.setAttribute("data-error-id", errorId)
    const msg = document.createElement("span")
    msg.id = errorId
    msg.setAttribute("role", "alert")
    msg.className = "mt-1 text-sm text-red-400"
    msg.textContent = "não pode ficar em branco"
    field.insertAdjacentElement("afterend", msg)
  }
}
