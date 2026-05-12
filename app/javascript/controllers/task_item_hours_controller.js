import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { previewId: String, valueId: String }

  calculate() {
    const startInput = this.element.querySelector("input[name$='[start_time]']")
    const endInput = this.element.querySelector("input[name$='[end_time]']")

    if (!startInput?.value || !endInput?.value) return

    const [sh, sm] = startInput.value.split(":").map(Number)
    const [eh, em] = endInput.value.split(":").map(Number)
    let diffMinutes = (eh * 60 + em) - (sh * 60 + sm)

    // virada de meia-noite
    if (diffMinutes < 0) diffMinutes += 24 * 60

    if (diffMinutes === 0) {
      document.getElementById(this.previewIdValue)?.classList.add("hidden")
      return
    }

    const hh = Math.floor(diffMinutes / 60).toString().padStart(2, "0")
    const mm = (diffMinutes % 60).toString().padStart(2, "0")
    const previewEl = document.getElementById(this.previewIdValue)
    const valueEl = document.getElementById(this.valueIdValue)

    if (previewEl && valueEl) {
      valueEl.textContent = `${hh}:${mm}`
      previewEl.classList.remove("hidden")
    }
  }
}
