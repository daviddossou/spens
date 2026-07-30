import { Controller } from "@hotwired/stimulus"

// Debounced live search: submits the form as the user types.
// Connects to data-controller="search-form" (on the form element).
export default class extends Controller {
  static targets = ["input", "clear"]
  static values = { delay: { type: Number, default: 300 } }

  connect() {
    this.toggleClear()
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  search() {
    this.toggleClear()
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.submit(), this.delayValue)
  }

  submit() {
    clearTimeout(this.timeout)
    const query = this.inputTarget.value.trim()
    if (query === this.lastQuery) return

    this.lastQuery = query
    this.element.requestSubmit()
  }

  clear() {
    this.inputTarget.value = ""
    this.inputTarget.focus()
    this.toggleClear()
    this.submit()
  }

  toggleClear() {
    if (this.hasClearTarget) {
      this.clearTarget.classList.toggle("hidden", this.inputTarget.value.length === 0)
    }
  }
}
