import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="transaction-form"
export default class extends Controller {
  static targets = ["optionalFields", "toggleButton"]

  connect() {
    // Ensure optional fields are hidden on initial load and after turbo frame updates
    if (this.hasOptionalFieldsTarget) {
      this.optionalFieldsTarget.classList.add('hidden')
    }
    
    // Reset toggle button text on connect (after turbo frame reload)
    if (this.hasToggleButtonTarget) {
      this.toggleButtonTarget.textContent = this.toggleButtonTarget.dataset.showText || 'More details'
    }
  }

  toggleDetails(event) {
    event.preventDefault()
    const optionalFields = this.optionalFieldsTarget
    const toggleButton = this.toggleButtonTarget

    if (optionalFields.classList.contains('hidden')) {
      optionalFields.classList.remove('hidden')
      toggleButton.textContent = toggleButton.dataset.hideText || 'Hide details'
    } else {
      optionalFields.classList.add('hidden')
      toggleButton.textContent = toggleButton.dataset.showText || 'More details'
    }
  }
}
