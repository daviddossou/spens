import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="onboarding--financial-goals"
export default class extends Controller {
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

      if (hasSelection) {
        submitButton.classList.remove('disabled')
      } else {
        submitButton.classList.add('disabled')
      }
    }
  }
}
