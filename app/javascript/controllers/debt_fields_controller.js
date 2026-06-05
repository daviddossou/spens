import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="debt-fields"
//
// Drives the person-first debt flow inside the unified transaction form:
//   pick a person -> (infer or choose a direction) -> pick an intent.
// It writes the hidden `kind` and `direction` fields the backend consumes and
// swaps the two intent labels client-side, so no per-keystroke server round-trip
// is needed. The person field (a tom-select) notifies us via a `tom-select:change`
// event wired as the `onPersonChange` action.
export default class extends Controller {
  static targets = [
    "kindInput",
    "directionInput",
    "directionPicker",
    "directionOption",
    "intents",
    "intentOption"
  ]

  static values = {
    intentLabels: Object, // { lent: { debt_in, debt_out }, borrowed: { ... } }
    debtsByName: Object,   // { "emmanuel": ["lent"], "eve": ["lent","borrowed"] }
    contactName: String,
    locked: Boolean
  }

  connect() {
    // Only the debt category renders the intents; bail out for expense/income/transfer.
    if (!this.hasIntentsTarget) return

    this.currentName = this.contactNameValue || ""
    const direction = this.directionInputTarget.value

    if (this.lockedValue) {
      // Opened from a specific debt: direction is known, both actions are valid.
      this.hidePicker()
      this.renderIntents(direction)
      this.selectIntentByKind(this.kindInputTarget.value)
    } else if (direction && this.directionExists(this.currentName, direction)) {
      // Existing debt with this direction: both actions are valid.
      this.hidePicker()
      this.renderIntents(direction)
      this.selectIntentByKind(this.kindInputTarget.value)
    } else if (direction) {
      // New debt: only the opening action is possible, so no intent choice.
      this.showPicker()
      this.markDirectionByValue(direction)
      this.hideIntents()
      this.kindInputTarget.value = this.openingKind(direction)
    } else if (this.currentName) {
      // A person is filled in but no direction yet (new or both-directions name).
      this.showPicker()
      this.hideIntents()
    } else {
      this.hidePicker()
      this.hideIntents()
    }
  }

  onPersonChange(event) {
    // tom-select emits a custom event with detail.value; a plain text input
    // (no existing debts to autocomplete) fires a native change instead.
    const raw = event.detail?.value ?? event.target?.value ?? ""
    const name = raw.trim()
    this.currentName = name
    this.directionInputTarget.value = ""
    this.clearDirectionSelection()

    if (!name) {
      this.hidePicker()
      this.hideIntents()
      return
    }

    const directions = this.debtsByNameValue[name.toLowerCase()] || []

    if (directions.length === 1) {
      // Existing person with a single relationship: infer the direction.
      this.directionInputTarget.value = directions[0]
      this.hidePicker()
      this.renderIntents(directions[0])
      this.selectDefaultIntent()
    } else {
      // New person (0) or a name used both ways (2): let the user choose.
      this.showPicker()
      this.hideIntents()
    }
  }

  selectDirection(event) {
    const direction = event.currentTarget.dataset.direction
    this.directionInputTarget.value = direction
    this.markDirectionSelected(event.currentTarget)

    if (this.directionExists(this.currentName, direction)) {
      // The person already has a debt in this direction: both actions are valid.
      this.renderIntents(direction)
      this.selectDefaultIntent()
    } else {
      // Brand-new debt: the first transaction can only open it (lent => money
      // lent, borrowed => money borrowed). There's nothing to repay yet, so we
      // skip the intent choice and set the opening action directly.
      this.hideIntents()
      this.kindInputTarget.value = this.openingKind(direction)
    }
  }

  selectIntent(event) {
    this.applyIntent(event.currentTarget)
  }

  // --- helpers ---------------------------------------------------------------

  // Does the typed person already have a debt in this direction?
  directionExists(name, direction) {
    return (this.debtsByNameValue[(name || "").toLowerCase()] || []).includes(direction)
  }

  // The only possible first transaction for a new debt: lending opens a "lent"
  // debt (debt_out / Money Lent), borrowing opens a "borrowed" one (debt_in /
  // Money Borrowed).
  openingKind(direction) {
    return direction === "lent" ? "debt_out" : "debt_in"
  }

  markDirectionByValue(direction) {
    const btn = this.directionOptionTargets.find((b) => b.dataset.direction === direction)
    if (btn) this.markDirectionSelected(btn)
  }

  renderIntents(direction) {
    if (!direction) {
      this.hideIntents()
      return
    }

    const labels = this.intentLabelsValue[direction] || {}
    this.intentOptionTargets.forEach((btn) => {
      const kind = btn.dataset.kind
      if (labels[kind]) {
        const labelEl = btn.querySelector("[data-label]") || btn
        labelEl.textContent = labels[kind]
      }
    })
    this.showIntents()
  }

  selectDefaultIntent() {
    const first = this.intentOptionTargets[0]
    if (first) this.applyIntent(first)
  }

  selectIntentByKind(kind) {
    const match = this.intentOptionTargets.find((btn) => btn.dataset.kind === kind)
    this.applyIntent(match || this.intentOptionTargets[0])
  }

  applyIntent(btn) {
    if (!btn) return
    this.kindInputTarget.value = btn.dataset.kind
    this.intentOptionTargets.forEach((b) =>
      b.classList.toggle("kind-option--selected", b === btn)
    )
  }

  markDirectionSelected(btn) {
    this.directionOptionTargets.forEach((b) =>
      b.classList.toggle("kind-option--selected", b === btn)
    )
  }

  clearDirectionSelection() {
    this.directionOptionTargets.forEach((b) =>
      b.classList.remove("kind-option--selected")
    )
  }

  showPicker() {
    if (this.hasDirectionPickerTarget) this.directionPickerTarget.classList.remove("hidden")
  }

  hidePicker() {
    if (this.hasDirectionPickerTarget) this.directionPickerTarget.classList.add("hidden")
  }

  showIntents() {
    if (this.hasIntentsTarget) this.intentsTarget.classList.remove("hidden")
  }

  hideIntents() {
    if (this.hasIntentsTarget) this.intentsTarget.classList.add("hidden")
  }
}
