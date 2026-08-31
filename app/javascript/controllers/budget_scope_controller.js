import { Controller } from "@hotwired/stimulus"
import { formatMoney } from "lib/money"

// Connects to data-controller="budget-scope"
// One sheet, two scopes for editing a budget line: "this month only" (a per-month
// exception) or "every month from here" (the recurring rule, unfolding its fields).
// The scope cards swap which fields, note and button the sheet shows.
export default class extends Controller {
  static targets = ["scopeInput", "scopeCard", "ruleBlock", "ruleHint", "noteMonth", "noteRule",
    "cta", "amount", "amberAmount"]
  static values = {
    currency: String, locale: String,
    ctaMonth: String, ctaRule: String
  }

  connect() { this.render() }

  setScope(event) {
    if (this.hasScopeInputTarget) this.scopeInputTarget.value = event.currentTarget.dataset.scope
    this.render()
  }

  onAmount() { this.syncAmber() }

  #scope() {
    return this.hasScopeInputTarget ? this.scopeInputTarget.value : "month"
  }

  render() {
    const rule = this.#scope() === "rule"

    this.scopeCardTargets.forEach((c) => c.classList.toggle("scope-card--selected", c.dataset.scope === this.#scope()))
    if (this.hasRuleBlockTarget) this.ruleBlockTarget.classList.toggle("hidden", !rule)
    // The always-visible rule summary folds away once its settings are open.
    if (this.hasRuleHintTarget) this.ruleHintTarget.classList.toggle("hidden", rule)
    if (this.hasNoteMonthTarget) this.noteMonthTarget.classList.toggle("hidden", rule)
    if (this.hasNoteRuleTarget) this.noteRuleTarget.classList.toggle("hidden", !rule)
    if (this.hasCtaTarget) this.ctaTarget.textContent = rule ? this.ctaRuleValue : this.ctaMonthValue

    this.syncAmber()
  }

  // The amber note names the new amount the changed months take on.
  syncAmber() {
    if (!this.hasAmberAmountTarget) return
    const raw = this.hasAmountTarget ? parseFloat(this.amountTarget.value) : NaN
    const text = raw > 0
      ? formatMoney(raw, this.currencyValue, this.hasLocaleValue ? this.localeValue : undefined)
      : ""
    this.amberAmountTargets.forEach((el) => { el.textContent = text })
  }
}
