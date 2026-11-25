import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toast"
// A toast that leaves by itself after `duration` ms (the "Annuler" of an import).
export default class extends Controller {
  static values = { duration: { type: Number, default: 8000 } }

  connect() {
    this.timer = setTimeout(() => this.dismiss(), this.durationValue)
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  dismiss() {
    this.element.classList.add("is-leaving")
    setTimeout(() => this.element.remove(), 250)
  }
}
