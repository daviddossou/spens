import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dismiss"
// A tip closed for good: removed at once, and the server remembers it for this user.
export default class extends Controller {
  static values = { url: String }

  close() {
    this.element.remove()
    if (!this.urlValue) return

    fetch(this.urlValue, {
      method: "POST",
      credentials: "same-origin",
      headers: { "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content || "" }
    }).catch(() => {})
  }
}
