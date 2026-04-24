import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, frame: String }

  navigate(event) {
    if (event.target.closest("a, button")) return
    const frame = document.querySelector(`turbo-frame#${this.frameValue}`)
    if (frame) {
      frame.src = this.urlValue
    }
  }
}
