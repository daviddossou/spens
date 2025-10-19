import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="onboarding--financial-goals"
export default class extends Controller {
  static targets = ["card"]
  static classes = ["selected"]

  connect() {
    this.updateCards()
  }

  toggle(event) {
    const card = event.currentTarget
    const checkbox = card.querySelector('input[type="checkbox"]')

    checkbox.checked = !checkbox.checked
    checkbox.dispatchEvent(new Event('change', { bubbles: true }))

    this.updateCardState(card, checkbox.checked)
    this.updateSubmitButton()
  }

  updateCards() {
    this.cardTargets.forEach(card => {
      const checkbox = card.querySelector('input[type="checkbox"]')
      if (checkbox) {
        this.updateCardState(card, checkbox.checked)
      }
    })
    this.updateSubmitButton()
  }

  updateCardState(card, isSelected) {
    card.classList.toggle('selected', isSelected)

    card.dataset.selected = isSelected.toString()
  } updateSubmitButton() {
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
