import { Controller } from "@hotwired/stimulus"

// Captures the device's IANA time zone and stores it on the user when it
// differs from what the server has — invisible, no setting to configure.
export default class extends Controller {
  static values = { current: String, url: String }

  connect() {
    const device = Intl.DateTimeFormat().resolvedOptions().timeZone
    if (!device || device === this.currentValue) return

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify({ time_zone: device })
    })
  }
}
