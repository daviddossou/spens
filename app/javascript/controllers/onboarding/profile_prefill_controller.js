import { Controller } from "@hotwired/stimulus"

// Prefills country and currency from the landing page's country picker choice
// (stored in localStorage). Only fills pickers the user hasn't answered yet.
export default class extends Controller {
  connect() {
    let saved
    try {
      const raw = localStorage.getItem("spens:landing-country")
      if (!raw) return
      saved = raw.startsWith("{") ? JSON.parse(raw) : { code: raw }
    } catch { return }

    // Defer so the picker controllers around the fields connect first.
    setTimeout(() => {
      if (saved.code) this.setPicker("country", saved.code)
      if (saved.cur) this.setPicker("currency", saved.cur, { override: "XOF" })
    }, 0)
  }

  // Sets a picker unless the user already chose something (an empty value, or
  // the given default that can be overridden, counts as unset).
  setPicker(field, value, { override } = {}) {
    const input = this.element.querySelector(`input[name*="[${field}]"]`)
    if (!input) return
    if (input.value !== "" && input.value !== override) return

    const picker = this.pickerFor(input)
    if (!picker || !picker.rowsValue.some((row) => row.value === value)) return

    input.value = value
    picker.render()
    input.dispatchEvent(new Event("change", { bubbles: true }))
  }

  pickerFor(input) {
    const el = input.closest('[data-controller~="picker"]')
    return el && this.application.getControllerForElementAndIdentifier(el, "picker")
  }
}
