import { Controller } from "@hotwired/stimulus"

// Wraps the real onboarding account lines on the landing page: live total
// (shown once an amount is typed). Line add/remove and autocomplete are handled
// by onboarding--account-setup; the rows reach sign-up through landing--handoff.
export default class extends Controller {
  static targets = ["total", "recap", "note"]

  connect() {
    this.tagCurrencyAddons()
    this.compute()
  }

  compute() {
    // After a tick, so added/removed lines are in the DOM when we read.
    requestAnimationFrame(() => {
      this.tagCurrencyAddons()
      let total = 0
      let hasAmount = false
      this.element.querySelectorAll("input[name*='[amount]']").forEach((input) => {
        if (input.value !== "") hasAmount = true
        total += parseFloat(input.value) || 0
      })
      this.totalTarget.textContent = total.toLocaleString(
        document.documentElement.lang === "en" ? "en" : "fr-FR"
      )
      this.recapTarget.hidden = !hasAmount
      this.noteTarget.hidden = !hasAmount
    })
  }

  // Enter inside the form goes to sign-up too, through the CTA so the rows ride along.
  submit(event) {
    event.preventDefault()
    this.element.querySelector("[data-landing--accounts-target~='recap'] a").click()
  }

  // Let the country picker drive the currency prefix of every line.
  tagCurrencyAddons() {
    const current = document.querySelector("[data-currency-label]")?.textContent
    this.element.querySelectorAll(".form-input-addon--prepend:not([data-currency-label])").forEach((el) => {
      el.setAttribute("data-currency-label", "")
      if (current) el.textContent = current
    })
  }
}
