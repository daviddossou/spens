import { Controller } from "@hotwired/stimulus"

// Prefills country and currency from the landing page's country picker choice
// (stored in localStorage). Only fills fields the user hasn't set yet.
export default class extends Controller {
  connect() {
    let saved
    try {
      const raw = localStorage.getItem("spens:landing-country")
      if (!raw) return
      saved = raw.startsWith("{") ? JSON.parse(raw) : { code: raw }
    } catch { return }

    // Defer so the tom-select controllers on the selects initialize first.
    setTimeout(() => {
      if (saved.code) this.setSelect("country", saved.code)
      if (saved.cur) this.setSelect("currency", saved.cur, { override: "XOF" })
    }, 0)
  }

  // Sets a select unless the user already chose something (an empty value, or
  // the given default that can be overridden, counts as unset).
  setSelect(field, value, { override } = {}) {
    const select = this.element.querySelector(`select[name*="[${field}]"]`)
    if (!select) return
    if (select.value !== "" && select.value !== override) return
    if (![...select.options].some((o) => o.value === value)) return
    if (select.tomselect) {
      select.tomselect.setValue(value)
    } else {
      select.value = value
      select.dispatchEvent(new Event("change", { bubbles: true }))
    }
  }
}
