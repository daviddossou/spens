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

  // When picking a category suggestion replaces what the user typed ("carrefour" →
  // "Provisions"), keep the typed text in the description so nothing is lost. Bound via
  // data-action on the form root; only reacts to the category field.
  keepTypedText(event) {
    const field = event.target
    if (!field.name || !field.name.includes("transaction_type_name")) return

    const typed = (field.dataset.typedQuery || "").trim()
    delete field.dataset.typedQuery
    if (!typed) return

    // Typing the category's own name (or creating it as a custom type) carries no extra info.
    const value = (event.detail?.value || "").toLowerCase()
    if (value.includes(typed.toLowerCase())) return

    const description = this.element.querySelector('[name="transaction[description]"]')
    if (description && !description.value) description.value = typed
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
