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
        field.classList.add("border-red-500")
        field.classList.remove("border-gray-600")
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
    }
  }
}
