import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]

  close() {
    this.messageTarget.remove()
  }
}
