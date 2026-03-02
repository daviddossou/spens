import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.inputTarget.focus()
  }

  handleInput(event) {
    const value = event.target.value.replace(/\D/g, '').slice(0, 6)
    event.target.value = value

    if (value.length === 6) {
      this.element.requestSubmit()
    }
  }
}
