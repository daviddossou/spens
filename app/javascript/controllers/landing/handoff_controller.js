import { Controller } from "@hotwired/stimulus"

// Carries the visitor's landing choices into the sign-up link: the country
// picked (an explicit pick only; a detected default is left to the server's
// guess), the calculator's income and rate when changed from their defaults,
// the diagnostic's goals and the accounts typed in. They travel as
// `landing[...]` query params so the server can keep them in session, which
// survives the jump from an in-app browser to the real one.
export default class extends Controller {
  connect() {
    this.onClick = (event) => {
      const link = event.target.closest("a[href]")
      if (link && this.element.contains(link) && this.signUpLink(link)) link.href = this.withChoices(link.href)
    }
    this.element.addEventListener("click", this.onClick, true)
  }

  disconnect() {
    this.element.removeEventListener("click", this.onClick, true)
  }

  signUpLink(link) {
    return /\/sign_up$/.test(new URL(link.href, window.location.href).pathname)
  }

  withChoices(href) {
    const url = new URL(href, window.location.href)
    const { country, currency, income, savingsRate, goals, accounts } = this.choices()

    url.searchParams.delete("landing[country]")
    url.searchParams.delete("landing[currency]")
    url.searchParams.delete("landing[income]")
    url.searchParams.delete("landing[savings_rate]")
    url.searchParams.delete("landing[goals]")
    url.searchParams.delete("landing[accounts][][name]")
    url.searchParams.delete("landing[accounts][][amount]")

    if (country) url.searchParams.set("landing[country]", country)
    if (currency) url.searchParams.set("landing[currency]", currency)
    if (income) url.searchParams.set("landing[income]", income)
    if (savingsRate) url.searchParams.set("landing[savings_rate]", savingsRate)
    if (goals.length > 0) url.searchParams.set("landing[goals]", goals.join(","))
    accounts.forEach(({ name, amount }) => {
      url.searchParams.append("landing[accounts][][name]", name)
      url.searchParams.append("landing[accounts][][amount]", amount)
    })
    return url.toString()
  }

  choices() {
    return { ...this.pickedCountry(), ...this.calculator(), goals: this.goals(), accounts: this.accounts() }
  }

  // Only a changed field is a choice; the defaults stay the onboarding's business.
  calculator() {
    const changed = (target) => {
      const el = this.element.querySelector(`[data-savings-calculator-target="${target}"]`)
      return el && el.value !== el.defaultValue ? el.value.replace(/[^\d]/g, "") : null
    }
    return { income: changed("income"), savingsRate: changed("slider") }
  }

  pickedCountry() {
    try {
      const raw = localStorage.getItem("spens:landing-country")
      if (!raw) return {}
      const saved = raw.startsWith("{") ? JSON.parse(raw) : { code: raw }
      return { country: saved.code, currency: saved.cur }
    } catch { return {} }
  }

  goals() {
    const cards = [...this.element.querySelectorAll("[data-landing--diagnostic-target~='card'].is-checked")]
    return [...new Set(cards.flatMap((c) => (c.dataset.goals || "").split(" ").filter(Boolean)))]
  }

  accounts() {
    return [...this.element.querySelectorAll("[data-onboarding--account-setup-target~='accountLine']")]
      .map((line) => ({
        name: line.querySelector("input[name*='[account_name]']")?.value?.trim() || "",
        amount: line.querySelector("input[name*='[amount]']")?.value || ""
      }))
      .filter((a) => a.name !== "")
  }
}
