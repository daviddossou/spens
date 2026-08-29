import { Controller } from "@hotwired/stimulus"
import { formatMoney } from "lib/money"

// Connects to data-controller="account-form"
// Drives the create/edit account form: the CTA names a missing name, a live
// recap says what pressing it will do, and on edit — once the balance is
// touched — a "where's the gap from?" card appears with the difference and,
// when there's a surplus, a shortcut to record it as real income instead.
export default class extends Controller {
  static targets = ["amount", "cta", "recap", "gap", "gapAmount", "recalibrateHint", "incomeLink", "incomeHint"]
  static values = {
    currency: String, locale: String,
    mode: String,               // "create" | "edit"
    originalBalance: Number,     // edit: the balance before any change
    total: Number,               // create: current total across accounts
    incomeUrl: String,           // edit: base URL to record the surplus as income
    ctaEmpty: String, ctaReady: String,
    recapCreate: String,         // "%{name} starts at %{amount} · total → %{total}"
    recapEdit: String,           // "We add Adjustment %{amount} on %{date}"
    gapMore: String, gapLess: String,       // "%{amount} more/less than expected"
    recalibrateHint: String,     // "An 'Adjustment %{amount}' line dated today"
    incomeHint: String           // "Opens an income entry of %{amount}"
  }

  connect() { this.syncAll() }

  onAmount() { this.syncAll() }
  onField() { this.syncCta(); this.syncRecap() }

  syncAll() { this.syncCta(); this.syncGap(); this.syncRecap() }

  #amount() {
    const raw = this.hasAmountTarget ? parseFloat(this.amountTarget.value) : NaN
    return Number.isFinite(raw) ? raw : 0
  }

  #name() { return this.element.querySelector('[name="account[account_name]"]')?.value?.trim() || "" }
  #money(value) { return formatMoney(Math.abs(value), this.currencyValue, this.hasLocaleValue ? this.localeValue : undefined) }
  #signed(value) { return `${value >= 0 ? "+" : "−"} ${this.#money(value)}` }

  #today() {
    return new Intl.DateTimeFormat(this.hasLocaleValue ? this.localeValue : undefined, { day: "numeric", month: "long" }).format(new Date())
  }

  // The button waits on the one thing that's required — a name.
  syncCta() {
    if (!this.hasCtaTarget) return
    if (!this.#name()) { this.ctaTarget.textContent = this.ctaEmptyValue; this.ctaTarget.disabled = true; return }
    this.ctaTarget.textContent = this.ctaReadyValue
    this.ctaTarget.disabled = false
  }

  // Edit only: reveal the gap between the typed balance and what was expected.
  syncGap() {
    if (this.modeValue !== "edit" || !this.hasGapTarget) return
    const diff = this.#amount() - this.originalBalanceValue

    if (Math.abs(diff) < 0.005) { this.gapTarget.classList.add("hidden"); return }
    this.gapTarget.classList.remove("hidden")

    this.gapAmountTarget.textContent = (diff > 0 ? this.gapMoreValue : this.gapLessValue).replace("%{amount}", this.#money(diff))
    this.recalibrateHintTarget.textContent = this.recalibrateHintValue.replace("%{amount}", this.#signed(diff))

    if (this.hasIncomeLinkTarget) {
      if (diff > 0) {
        this.incomeLinkTarget.classList.remove("hidden")
        this.incomeHintTarget.textContent = this.incomeHintValue.replace("%{amount}", this.#money(diff))
        const sep = this.incomeUrlValue.includes("?") ? "&" : "?"
        this.incomeLinkTarget.href = `${this.incomeUrlValue}${sep}amount=${Math.abs(diff)}`
      } else {
        this.incomeLinkTarget.classList.add("hidden")
      }
    }
  }

  syncRecap() {
    if (!this.hasRecapTarget) return
    const amount = this.#amount()

    if (this.modeValue === "edit") {
      const diff = amount - this.originalBalanceValue
      if (Math.abs(diff) < 0.005) { this.recapTarget.hidden = true; return }
      this.recapTarget.textContent = this.recapEditValue.replace("%{amount}", this.#signed(diff)).replace("%{date}", this.#today())
      this.recapTarget.hidden = false
      return
    }

    const name = this.#name()
    if (!name || !(amount > 0)) { this.recapTarget.hidden = true; return }
    this.recapTarget.textContent = this.recapCreateValue
      .replace("%{name}", name)
      .replace("%{amount}", this.#money(amount))
      .replace("%{total}", this.#money(this.totalValue + amount))
    this.recapTarget.hidden = false
  }
}
