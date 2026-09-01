import { Controller } from "@hotwired/stimulus"

// A choice field. The list never opens under the field — tapping hands over to
// the shared layer (Tour 31), which writes back here and closes. The field
// itself is a button, so no keyboard is ever summoned by choosing.
export default class extends Controller {
  static targets = ["input", "label"]
  static values = {
    title: String,
    rows: Array,
    allowCreate: Boolean,
    placeholder: String,
    emptyLabel: String,
    grouped: Boolean,
    chainTo: String,
    chainReason: String
  }

  connect() {
    this.render()
  }

  open() {
    // A keypad open for the amount gives its space back in the same gesture.
    if (document.activeElement && document.activeElement.blur) document.activeElement.blur()
    this.layer?.present(this.request())
  }

  // What this field asks the layer to paint. `extra` carries the two-step bits.
  request(extra = {}) {
    return {
      title: this.titleValue,
      rows: this.rowsValue,
      selected: this.inputTarget.value,
      allowCreate: this.allowCreateValue,
      emptyLabel: this.hasEmptyLabelValue ? this.emptyLabelValue : null,
      grouped: this.groupedValue,
      onSelect: (row, typed) => this.commit(row, typed),
      ...extra
    }
  }

  commit(row, typed) {
    const value = row ? row.value : ""
    this.inputTarget.value = value

    if (row && row.balance !== undefined && row.balance !== null) {
      this.inputTarget.dataset.balance = row.balance
    } else {
      delete this.inputTarget.dataset.balance
    }
    if (typed) this.inputTarget.dataset.typedQuery = typed

    this.render()
    this.inputTarget.dispatchEvent(new CustomEvent("tom-select:change", { bubbles: true, detail: { value } }))
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))

    return this.chain(value)
  }

  // Transfer: picking the source runs straight into the destination, which
  // greys the account just chosen instead of refusing it afterwards.
  chain(value) {
    if (!this.hasChainToValue || !value) return null
    const next = this.pickerFor(this.chainToValue)
    if (!next) return null

    return next.request({
      step: "2 / 2",
      context: { label: this.titleValue, value: value, action: this.element.dataset.pickerChangeLabel },
      onContextAction: () => this.request({ step: "1 / 2" }),
      disabled: { [value]: this.chainReasonValue }
    })
  }

  // The label a closed field shows: the choice in full text, or the prompt.
  render() {
    if (!this.hasLabelTarget) return
    const row = this.rowsValue.find((r) => r.value === this.inputTarget.value)
    const chosen = this.inputTarget.value
    const empty = chosen === "" && this.hasEmptyLabelValue && this.inputTarget.dataset.pickerAnswered === "true"

    this.labelTarget.textContent = row ? row.label : (chosen || (empty ? this.emptyLabelValue : this.placeholderValue))
    this.labelTarget.classList.toggle("picker__value--empty", !chosen && !empty)
  }

  get layer() {
    const el = document.getElementById("picker-layer")
    return el && this.application.getControllerForElementAndIdentifier(el, "picker-layer")
  }

  pickerFor(selector) {
    const el = document.querySelector(selector)
    return el && this.application.getControllerForElementAndIdentifier(el, "picker")
  }
}
