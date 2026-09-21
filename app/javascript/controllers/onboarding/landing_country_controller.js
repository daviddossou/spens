import { Controller } from "@hotwired/stimulus"
import { currencySymbol } from "lib/currency_symbols"

// Carries what the browser knows about where the user lives into the first
// onboarding step: the country picked on the landing page and the time zone.
// A picked currency also replaces the server's guess on screen.
export default class extends Controller {
  static targets = ["country", "currency", "timeZone", "code", "symbol"]
  static values = { confirmed: Boolean }

  connect() {
    try { this.timeZoneTarget.value = Intl.DateTimeFormat().resolvedOptions().timeZone || "" } catch {}
    if (this.confirmedValue) return

    const picked = this.pickedCountry()
    if (!picked) return

    this.countryTarget.value = picked.code || ""
    if (!picked.cur) return

    this.currencyTarget.value = picked.cur
    this.codeTargets.forEach((el) => { el.textContent = picked.cur })
    this.symbolTargets.forEach((el) => { el.textContent = currencySymbol(picked.cur) })
  }

  pickedCountry() {
    try {
      const raw = localStorage.getItem("spens:landing-country")
      if (!raw) return null
      return raw.startsWith("{") ? JSON.parse(raw) : { code: raw }
    } catch { return null }
  }
}
