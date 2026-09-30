import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="onboarding--account-setup"
export default class extends Controller {
  static targets = ["accountsContainer", "accountLine", "addButton", "template"]
  static values = { currency: String }

  connect() {
    this.updateRemoveButtons()
  }

  addLine(event) {
    event.preventDefault()

    const newIndex = this.accountLineTargets.length

    // Clone the template
    const template = this.templateTarget.content.cloneNode(true)
    const wrapper = document.createElement('div')
    wrapper.appendChild(template)

    // Update all field names and IDs with the new index
    this.updateFieldNamesAndIds(wrapper, newIndex)

    // Append to container (appendChild moves the node out of the wrapper)
    this.accountsContainerTarget.appendChild(wrapper.firstElementChild)

    this.updateRemoveButtons()
  }

  removeLine(event) {
    event.preventDefault()

    const line = event.target.closest('[data-onboarding--account-setup-target="accountLine"]')

    // Don't allow removing if it's the only line
    if (this.accountLineTargets.length > 1) {
      line.remove()
      this.updateRemoveButtons()
      this.reindexLines()
    }
  }

  updateRemoveButtons() {
    const lines = this.accountLineTargets
    const canRemove = lines.length > 1

    lines.forEach(line => {
      const removeButtonWrapper = line.querySelector('.account-line__remove-button')
      if (removeButtonWrapper) {
        if (canRemove) {
          removeButtonWrapper.style.display = 'flex'
        } else {
          removeButtonWrapper.style.display = 'none'
        }
      }
    })
  }

  updateFieldNamesAndIds(element, index) {
    // Update all input names (handles both numeric indices and TEMPLATE_INDEX)
    element.querySelectorAll('input, select, textarea').forEach(field => {
      if (field.name) {
        // Replace both [transactions_attributes][TEMPLATE_INDEX] and [transactions_attributes][0]
        field.name = field.name.replace(
          /\[transactions_attributes\]\[(?:TEMPLATE_INDEX|\d+)\]/,
          `[transactions_attributes][${index}]`
        )
      }
      if (field.id) {
        // Replace both _transactions_attributes_TEMPLATE_INDEX_ and _transactions_attributes_0_
        field.id = field.id.replace(
          /_transactions_attributes_(?:TEMPLATE_INDEX|\d+)_/,
          `_transactions_attributes_${index}_`
        )
      }
    })

    // Update labels
    element.querySelectorAll('label').forEach(label => {
      if (label.htmlFor) {
        label.htmlFor = label.htmlFor.replace(
          /_transactions_attributes_(?:TEMPLATE_INDEX|\d+)_/,
          `_transactions_attributes_${index}_`
        )
      }
    })
  }

  reindexLines() {
    this.accountLineTargets.forEach((line, index) => {
      this.updateFieldNamesAndIds(line, index)
    })
  }
}
