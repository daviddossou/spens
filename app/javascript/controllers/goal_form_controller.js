import { Controller } from "@hotwired/stimulus"
import { formatMoney } from "lib/money"

// Connects to data-controller="goal-form"
// Drives the create/edit goal form: the target amount feeds the CTA (which
// names what's still missing) and, with the deadline pills, a live "so that's
// X a month" rhythm line. Picking an account prefills what's already put aside.
export default class extends Controller {
  static targets = ["amount", "currentBalance", "accountName", "cta", "rhythm",
    "deadlinePill", "deadlineField", "deadlineInput"]
  static values = {
    currency: String, locale: String,
    ctaEmpty: String, ctaNoName: String, ctaNoAccount: String, ctaReady: String,
    rhythmTemplate: String // "Soit %{amount} par mois jusqu'en %{month}"
  }

  connect() {
    if (this.hasAccountNameTarget) {
      this._onAccount = this.handleAccountChange.bind(this)
      this.accountNameTarget.addEventListener("change", this._onAccount)
    }
    // Restore an existing deadline on edit: mark it a specific date, shown.
    if (this.hasDeadlineInputTarget && this.deadlineInputTarget.value) {
      this.activatePill("other")
      this.deadlineFieldTarget?.classList.remove("hidden")
    }
    this.syncAll()
  }

  disconnect() {
    if (this.hasAccountNameTarget && this._onAccount) {
      this.accountNameTarget.removeEventListener("change", this._onAccount)
    }
  }

  onAmount() { this.syncAll() }
  onField() { this.syncAll() }

  syncAll() { this.syncCta(); this.syncRhythm() }

  // Account picked → prefill "already put aside" with its live balance.
  handleAccountChange() {
    setTimeout(() => {
      const balance = this.accountNameTarget.dataset.balance
      if (balance !== undefined && balance !== null && balance !== "" && this.hasCurrentBalanceTarget) {
        this.currentBalanceTarget.value = balance
        this.currentBalanceTarget.dispatchEvent(new Event("input", { bubbles: true }))
      }
      this.syncAll()
    }, 50)
  }

  #num(target) {
    return target && target.value !== "" ? parseFloat(target.value) : NaN
  }

  #target() { return this.hasAmountTarget ? this.#num(this.amountTarget) : NaN }
  #saved() { return this.hasCurrentBalanceTarget ? (this.#num(this.currentBalanceTarget) || 0) : 0 }
  #fieldValue(field) { return this.element.querySelector(`[name="goal[${field}]"]`)?.value?.trim() || "" }
  #money(value) { return formatMoney(value, this.currencyValue, this.hasLocaleValue ? this.localeValue : undefined) }

  // The button replaces red asterisks: disabled until every required field is
  // filled, naming the next missing one — target, then name, then account.
  syncCta() {
    if (!this.hasCtaTarget) return
    if (!(this.#target() > 0)) return this.setCta(this.ctaEmptyValue, true)
    if (!this.#fieldValue("goal_name")) return this.setCta(this.ctaNoNameValue, true)
    if (!this.#fieldValue("account_name")) return this.setCta(this.ctaNoAccountValue, true)
    this.setCta(this.ctaReadyValue, false)
  }

  setCta(text, disabled) {
    this.ctaTarget.textContent = text
    this.ctaTarget.disabled = disabled
  }

  // "Soit 30 000 par mois jusqu'en août 2027" — what's left to save, spread over
  // the months to the deadline. Hidden until a target and a date are both set.
  syncRhythm() {
    if (!this.hasRhythmTarget) return
    const target = this.#target()
    const iso = this.hasDeadlineInputTarget ? this.deadlineInputTarget.value : ""
    const remaining = target - this.#saved()
    if (!(target > 0) || !iso || !(remaining > 0)) { this.rhythmTarget.hidden = true; return }

    const months = this.#monthsUntil(iso)
    if (months < 1) { this.rhythmTarget.hidden = true; return }

    let monthly = remaining / months
    monthly = monthly >= 10000 ? Math.round(monthly / 1000) * 1000 : Math.round(monthly)
    this.rhythmTarget.textContent = this.rhythmTemplateValue
      .replace("%{amount}", this.#money(monthly))
      .replace("%{month}", this.#monthLabel(iso))
    this.rhythmTarget.hidden = false
  }

  // Deadline as pills: in 6 months / in 1 year / a specific date / none.
  setDeadline(event) {
    const mode = event.currentTarget.dataset.deadlineMode
    this.activatePill(mode)
    if (mode === "other") {
      this.deadlineFieldTarget?.classList.remove("hidden")
    } else {
      this.deadlineFieldTarget?.classList.add("hidden")
      if (this.hasDeadlineInputTarget) {
        this.deadlineInputTarget.value = mode === "m6" ? this.#inMonths(6) : mode === "y1" ? this.#inMonths(12) : ""
      }
    }
    this.syncRhythm()
  }

  onDeadlineInput() { this.activatePill("other"); this.syncRhythm() }

  activatePill(mode) {
    this.deadlinePillTargets.forEach((p) => p.classList.toggle("pill--active", p.dataset.deadlineMode === mode))
  }

  #inMonths(n) {
    const d = new Date()
    d.setMonth(d.getMonth() + n)
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`
  }

  // Months from this month through the deadline month, inclusive — mirrors
  // GoalProgress so the preview matches what the goal will later show.
  #monthsUntil(iso) {
    const [y, m] = iso.split("-").map(Number)
    const now = new Date()
    return (y - now.getFullYear()) * 12 + (m - (now.getMonth() + 1)) + 1
  }

  #monthLabel(iso) {
    const [y, m] = iso.split("-").map(Number)
    const date = new Date(y, m - 1, 1)
    return new Intl.DateTimeFormat(this.hasLocaleValue ? this.localeValue : undefined, { month: "long", year: "numeric" }).format(date)
  }
}
