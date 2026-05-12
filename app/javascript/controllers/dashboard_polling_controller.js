import { Controller } from "@hotwired/stimulus"
import * as Turbo from "@hotwired/turbo"

export default class extends Controller {
  static values = { url: String, eventsUrl: String }

  connect() {
    this.source = new EventSource(this.eventsUrlValue)
    this.source.addEventListener("dashboard-update", (e) => {
      Turbo.renderStreamMessage(e.data)
    })
  }

  disconnect() {
    this.source?.close()
  }
}
