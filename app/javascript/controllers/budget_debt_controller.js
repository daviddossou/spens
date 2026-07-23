import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="budget-debt"
//
// Drives the debt branch of the budget-line form: two direction pills write the
// hidden `kind` field (debt_in: they pay me, debt_out: I pay them), and picking
// an existing person preselects the direction from their ongoing debt. The
// person field (a tom-select) notifies us via `tom-select:change`.
export default class extends Controller {
  static targets = ["kindInput", "option"]

  static values = {
    kindsByName: Object // { "georges": ["debt_in"], "eve": ["debt_in", "debt_out"] }
  }

  connect() {
    this.markSelected(this.kindInputTarget.value)
  }

  select(event) {
    this.apply(event.currentTarget.dataset.kind)
  }

  onPersonChange(event) {
    const name = (event.detail?.value ?? event.target.value ?? "").trim().toLowerCase()
    const kinds = this.kindsByNameValue[name]
    if (kinds && kinds.length === 1) this.apply(kinds[0])
  }

  apply(kind) {
    this.kindInputTarget.value = kind
    this.markSelected(kind)
  }

  markSelected(kind) {
    this.optionTargets.forEach((option) => {
      const selected = option.dataset.kind === kind
      option.classList.toggle("kind-option--selected", selected)
      option.setAttribute("aria-checked", selected.toString())
    })
  }
}
