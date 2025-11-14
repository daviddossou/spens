import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="goal-form"
export default class extends Controller {
  static targets = ["accountName", "currentBalance"]

  connect() {
    // Set up the change listener on the account name input
    if (this.hasAccountNameTarget) {
      this.accountNameTarget.addEventListener('change', this.handleAccountChange.bind(this))
    }
  }

  handleAccountChange(event) {
    // Use a small timeout to ensure TomSelect has updated the data attribute
    // TomSelect's change event fires after the input's change event
    setTimeout(() => {
      const balance = this.accountNameTarget.dataset.balance

      if (balance !== undefined && balance !== null && balance !== '') {
        // Update the current balance field
        if (this.hasCurrentBalanceTarget) {
          this.currentBalanceTarget.value = balance
          // Trigger input event so any other listeners are notified
          this.currentBalanceTarget.dispatchEvent(new Event('input', { bubbles: true }))
        }
      }
    }, 50)
  }

  disconnect() {
    if (this.hasAccountNameTarget) {
      this.accountNameTarget.removeEventListener('change', this.handleAccountChange.bind(this))
    }
  }
}
