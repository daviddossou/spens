import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="ui--selectable-card"
export default class extends Controller {
  static targets = ["checkbox", "radio"]

  toggle(event) {
    const input = this.inputTarget
    const inputType = input.type

    // Prevent the click from bubbling if it's already on the input
    if (event.target.matches('input[type="checkbox"]') || event.target.matches('input[type="radio"]')) {
      this.updateCardState()
      return
    }

    event.preventDefault()

    if (inputType === 'radio') {
      // For radio buttons, we need to deselect all other cards in the same group
      input.checked = true
      input.dispatchEvent(new Event('change', { bubbles: true }))
      this.updateAllRadioCardsInGroup()
    } else {
      // For checkboxes, toggle the current state
      input.checked = !input.checked
      input.dispatchEvent(new Event('change', { bubbles: true }))
      this.updateCardState()
    }
  }

  checkboxTargetConnected() {
    this.updateCardState()
  }

  radioTargetConnected() {
    this.updateCardState()
  }

  updateCardState() {
    const input = this.inputTarget
    const isSelected = input.checked

    this.element.classList.toggle('selected', isSelected)
    this.element.dataset.selected = isSelected.toString()
  }

  updateAllRadioCardsInGroup() {
    const input = this.inputTarget
    const name = input.name

    // Find all radio buttons with the same name
    const radios = document.querySelectorAll(`input[type="radio"][name="${name}"]`)

    radios.forEach(radio => {
      // Find the card element that contains this radio button
      const card = radio.closest('[data-controller*="ui--selectable-card"]')
      if (card) {
        const isSelected = radio.checked
        card.classList.toggle('selected', isSelected)
        card.dataset.selected = isSelected.toString()
      }
    })
  }

  get inputTarget() {
    // Return checkbox or radio target, whichever exists
    return this.hasCheckboxTarget ? this.checkboxTarget : this.radioTarget
  }
}
