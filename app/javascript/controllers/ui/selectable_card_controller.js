import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="ui--selectable-card"
export default class extends Controller {
  static targets = ["checkbox"]

  toggle(event) {
    // Prevent the click from bubbling if it's already on the checkbox
    if (event.target.matches('input[type="checkbox"]')) {
      this.updateCardState()
      return
    }

    event.preventDefault()
    
    const checkbox = this.checkboxTarget
    checkbox.checked = !checkbox.checked
    checkbox.dispatchEvent(new Event('change', { bubbles: true }))
    
    this.updateCardState()
  }

  checkboxTargetConnected() {
    this.updateCardState()
  }

  updateCardState() {
    const checkbox = this.checkboxTarget
    const isSelected = checkbox.checked
    
    this.element.classList.toggle('selected', isSelected)
    this.element.dataset.selected = isSelected.toString()
  }
}
