import { Controller } from "@hotwired/stimulus"
import { formatMoney } from "lib/money"

// Connects to data-controller="debt-form"
// Drives the create/edit debt form: direction tiles swap the labels and recap,
// the amount feeds both the CTA (which names what's missing) and the recap
// sentence, and the deadline pills compute a date without a calendar.
export default class extends Controller {
  static targets = ["amount", "amountLabel", "accountLabel", "cta", "recap",
    "deadlinePill", "deadlineField", "deadlineInput", "deadlineHint"]
  static values = {
    currency: String, locale: String,
    amountLabel: Object,      // { lent, borrowed }
    accountLabel: Object,     // { lent, borrowed }
    accountPlaceholder: Object, // { lent, borrowed }
    ctaTemplate: Object,      // { lent, borrowed } with %{amount}
    ctaEmpty: String,         // no amount yet
    ctaNoName: String,        // amount set, name still missing
    recap: Object,            // { lent, borrowed } with %{amount} %{name}
    recapAccount: Object      // { lent, borrowed } with %{account}
  }

  connect() { this.syncAll() }

  onDirection() { this.syncAll() }
  onAmount() { this.syncCta(); this.syncRecap() }
  onField() { this.syncCta(); this.syncRecap() }

  syncAll() {
    this.syncAmountLabel()
    this.syncAccount()
    this.syncCta()
    this.syncRecap()
  }

  // "Depuis quel compte ?" (lent) vs "Sur quel compte ?" (borrowed), and the
  // placeholder — money leaves you when you lend, lands when you borrow — both
  // follow the side, live, when the direction is toggled.
  syncAccount() {
    const dir = this.direction()
    if (this.hasAccountLabelTarget && this.hasAccountLabelValue) {
      this.accountLabelTarget.textContent = this.accountLabelValue[dir] || ""
    }
    if (!this.hasAccountPlaceholderValue) return
    const placeholder = this.accountPlaceholderValue[dir] || ""
    const input = this.element.querySelector('[name="debt[account_name]"]')
    if (!input) return
    const control = input.tomselect?.control_input
    if (control) control.setAttribute("placeholder", placeholder)
    else input.setAttribute("placeholder", placeholder)
  }

  direction() {
    return this.element.querySelector('input[name="debt[direction]"]:checked')?.value || "lent"
  }

  #amount() {
    return this.hasAmountTarget ? parseFloat(this.amountTarget.value) : NaN
  }

  #money(value) {
    return formatMoney(value, this.currencyValue, this.hasLocaleValue ? this.localeValue : undefined)
  }

  #fieldValue(field) {
    return this.element.querySelector(`[name="debt[${field}]"]`)?.value?.trim() || ""
  }

  syncAmountLabel() {
    if (!this.hasAmountLabelTarget) return
    this.amountLabelTarget.textContent = this.amountLabelValue[this.direction()] || ""
  }

  // The button replaces red asterisks: it stays disabled until every required
  // field is filled and names the next missing one — amount first, then the
  // person — before turning into "Enregistrer le prêt 111 000 FCFA".
  syncCta() {
    if (!this.hasCtaTarget) return
    const raw = this.#amount()
    if (!(raw > 0)) {
      this.ctaTarget.textContent = this.ctaEmptyValue
      this.ctaTarget.disabled = true
      return
    }
    if (!this.#fieldValue("contact_name")) {
      this.ctaTarget.textContent = this.ctaNoNameValue
      this.ctaTarget.disabled = true
      return
    }
    this.ctaTarget.textContent = (this.ctaTemplateValue[this.direction()] || "").replace("%{amount}", this.#money(raw))
    this.ctaTarget.disabled = false
  }

  // "Tu prêtes 111 000 FCFA à Fanélia · l'argent sort de MTN Mobile Money."
  syncRecap() {
    if (!this.hasRecapTarget) return
    const raw = this.#amount()
    const name = this.#fieldValue("contact_name")
    if (!(raw > 0) || !name) { this.recapTarget.hidden = true; return }

    const dir = this.direction()
    let text = (this.recapValue[dir] || "").replace("%{amount}", this.#money(raw)).replace("%{name}", name)
    const account = this.#fieldValue("account_name")
    if (account) text += " " + (this.recapAccountValue[dir] || "").replace("%{account}", account)
    this.recapTarget.textContent = text
    this.recapTarget.hidden = false
  }

  // Deadline as pills: end of this month / in 3 months / a specific date.
  setDeadline(event) {
    const mode = event.currentTarget.dataset.deadlineMode
    this.deadlinePillTargets.forEach((p) => p.classList.toggle("pill--active", p.dataset.deadlineMode === mode))
    if (mode === "other") {
      this.deadlineFieldTarget?.classList.remove("hidden")
    } else {
      this.deadlineFieldTarget?.classList.add("hidden")
      if (this.hasDeadlineInputTarget) {
        this.deadlineInputTarget.value = mode === "eom" ? this.#endOfMonth() : this.#inMonths(3)
      }
    }
    this.syncDeadlineHint()
  }

  onDeadlineInput() {
    this.deadlinePillTargets.forEach((p) => p.classList.toggle("pill--active", p.dataset.deadlineMode === "other"))
    this.syncDeadlineHint()
  }

  syncDeadlineHint() {
    if (!this.hasDeadlineHintTarget) return
    const iso = this.hasDeadlineInputTarget ? this.deadlineInputTarget.value : ""
    this.deadlineHintTarget.textContent = iso ? this.#fmtDate(iso) : ""
  }

  #endOfMonth() {
    const d = new Date()
    return this.#iso(new Date(d.getFullYear(), d.getMonth() + 1, 0))
  }

  #inMonths(n) {
    const d = new Date()
    d.setMonth(d.getMonth() + n)
    return this.#iso(d)
  }

  #iso(d) {
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`
  }

  #fmtDate(value) {
    const [y, m, d] = value.split("-")
    return `${d}/${m}/${y}`
  }
}
