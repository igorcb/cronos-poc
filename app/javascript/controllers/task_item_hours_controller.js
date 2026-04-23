import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { previewId: String, valueId: String }

  calculate() {
    const startInput = this.element.querySelector("input[name$='[start_time]']")
    const endInput = this.element.querySelector("input[name$='[end_time]']")

    if (!startInput?.value || !endInput?.value) return

    const [sh, sm] = startInput.value.split(":").map(Number)
    const [eh, em] = endInput.value.split(":").map(Number)
    const diffMinutes = (eh * 60 + em) - (sh * 60 + sm)

    if (diffMinutes <= 0) {
      document.getElementById(this.previewIdValue)?.classList.add("hidden")
      return
    }

    const hours = (diffMinutes / 60).toFixed(2)
    const previewEl = document.getElementById(this.previewIdValue)
    const valueEl = document.getElementById(this.valueIdValue)

    if (previewEl && valueEl) {
      valueEl.textContent = `${hours}h`
      previewEl.classList.remove("hidden")
    }
  }
}
