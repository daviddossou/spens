import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="onboarding--financial-goals"
export default class extends Controller {
  static values = { emptyLabel: String, readyLabel: String }

  connect() {
    this.updateSubmitButton()

    // Listen for checkbox changes to update submit button
    this.element.addEventListener('change', (event) => {
      if (event.target.matches('input[type="checkbox"]')) {
        this.updateSubmitButton()
      }
    })
  }

  updateSubmitButton() {
    const submitButton = this.element.querySelector('input[type="submit"], button[type="submit"]')
    const checkedBoxes = this.element.querySelectorAll('input[type="checkbox"]:checked')

    if (submitButton) {
      const hasSelection = checkedBoxes.length > 0
      submitButton.disabled = !hasSelection
      submitButton.classList.toggle('disabled', !hasSelection)
      // The button names what's missing instead of sitting grey and mute.
      if (this.hasEmptyLabelValue && this.hasReadyLabelValue) {
        submitButton.textContent = hasSelection ? this.readyLabelValue : this.emptyLabelValue
      }
    }
  }
}
