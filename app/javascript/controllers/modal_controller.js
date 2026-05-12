import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this._handleEscape = this.closeOnEscape.bind(this)
    document.addEventListener("keydown", this._handleEscape)
  }

  disconnect() {
    document.removeEventListener("keydown", this._handleEscape)
  }

  close() {
    const frame = document.querySelector("turbo-frame#modal")
    if (frame) frame.innerHTML = ""
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close()
  }

  closeOnOverlayClick(event) {
    if (event.target === this.element) this.close()
  }
}
