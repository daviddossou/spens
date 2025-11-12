import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="transaction-form"
export default class extends Controller {
  static targets = ["optionalFields", "toggleButton"]

  toggleDetails(event) {
    event.preventDefault()
    const optionalFields = this.optionalFieldsTarget
    const toggleButton = this.toggleButtonTarget

    if (optionalFields.style.display === 'none') {
      optionalFields.style.display = 'block'
      toggleButton.textContent = toggleButton.dataset.hideText || 'Hide details'
    } else {
      optionalFields.style.display = 'none'
      toggleButton.textContent = toggleButton.dataset.showText || 'More details'
    }
  }
}
