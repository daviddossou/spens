import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="transaction-form"
export default class extends Controller {
  static targets = ["optionalFields", "toggleButton"]

  connect() {
    // Start collapsed unless the server marked the section expanded (e.g. an
    // existing fee to edit). Keep this in sync after turbo frame updates.
    const expanded = this.hasOptionalFieldsTarget &&
      this.optionalFieldsTarget.dataset.expanded === 'true'

    if (this.hasOptionalFieldsTarget) {
      this.optionalFieldsTarget.classList.toggle('hidden', !expanded)
    }

    if (this.hasToggleButtonTarget) {
      const button = this.toggleButtonTarget
      button.textContent = expanded
        ? (button.dataset.hideText || 'Hide details')
        : (button.dataset.showText || 'More details')
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
