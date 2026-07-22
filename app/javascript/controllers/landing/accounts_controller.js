import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "spens:landing-accounts"

// Wraps the real onboarding account lines on the landing page: live total
// (shown once an amount is typed) and stashing the rows for onboarding prefill.
// Line add/remove and autocomplete are handled by onboarding--account-setup.
export default class extends Controller {
  static targets = ["total", "recap", "note"]

  connect() {
    this.tagCurrencyAddons()
    this.compute()
  }

  lines() {
    return [...this.element.querySelectorAll("[data-onboarding--account-setup-target~='accountLine']")]
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

  // Enter inside the form goes to sign-up too, with the rows stashed first.
  submit(event) {
    event.preventDefault()
    this.save()
    window.location.href = this.element.querySelector("[data-landing--accounts-target~='recap'] a").href
  }

  // Keep the entered rows so onboarding can prefill the real account form.
  save() {
    const accounts = this.lines()
      .map((line) => ({
        name: line.querySelector("input[name*='[account_name]']")?.value?.trim() || "",
        amount: line.querySelector("input[name*='[amount]']")?.value || "",
      }))
      .filter((a) => a.name !== "" || a.amount !== "")
    try {
      if (accounts.length > 0) localStorage.setItem(STORAGE_KEY, JSON.stringify(accounts))
    } catch {}
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
