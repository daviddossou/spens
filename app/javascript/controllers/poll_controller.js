import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="poll"
// Refreshes its content from `url` every `interval` ms (the analysis screen of an import). When
// the fresh content carries data-poll-done-url, polling stops and the page moves on.
export default class extends Controller {
  static values = { url: String, interval: { type: Number, default: 1500 } }

  connect() {
    this.timer = setInterval(() => this.refresh(), this.intervalValue)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  async refresh() {
    let response
    try {
      response = await fetch(this.urlValue, { headers: { Accept: "text/html" }, credentials: "same-origin" })
    } catch {
      return // offline for a moment: try again on the next tick
    }
    if (!response.ok) return

    this.element.innerHTML = await response.text()
    const done = this.element.querySelector("[data-poll-done-url]")
    if (done) {
      clearInterval(this.timer)
      window.Turbo.visit(done.dataset.pollDoneUrl, { action: "replace" })
    }
  }
}
