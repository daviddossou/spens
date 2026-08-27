import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="transaction-form"
export default class extends Controller {
  static targets = ["optionalFields", "toggleButton", "amount", "cta", "balances",
    "datePill", "dateField", "dateInput", "dateHint"]
  static values = {
    currency: String, locale: String, ctaTemplate: String, ctaEmpty: String, balances: Object,
    dateToday: String, dateYesterday: String
  }

  connect() {
    // Start collapsed unless the server marked the section expanded (e.g. an
    // existing fee to edit). Keep this in sync after turbo frame updates.
    const expanded = this.hasOptionalFieldsTarget &&
      this.optionalFieldsTarget.dataset.expanded === 'true'

    if (this.hasOptionalFieldsTarget) {
      this.optionalFieldsTarget.classList.toggle('hidden', !expanded)
    }

    if (this.hasToggleButtonTarget) {
      const button = this.toggleButtonTarget
      button.textContent = expanded
        ? (button.dataset.hideText || 'Hide details')
        : (button.dataset.showText || 'More details')
    }

    this.syncCta()
    this.syncBalances()
    this.syncDate()
  }

  // Date as Today / Yesterday / Other-date pills, with the choice echoed on the
  // right of the label.
  setDate(event) {
    const mode = event.currentTarget.dataset.dateMode
    this.datePillTargets.forEach((p) => p.classList.toggle("pill--active", p.dataset.dateMode === mode))
    if (mode === "other") {
      this.dateFieldTarget?.classList.remove("hidden")
    } else {
      this.dateFieldTarget?.classList.add("hidden")
      if (this.hasDateInputTarget) this.dateInputTarget.value = this.#iso(mode === "yesterday" ? -1 : 0)
    }
    this.syncDate(mode)
  }

  onDateInput() {
    this.datePillTargets.forEach((p) => p.classList.toggle("pill--active", p.dataset.dateMode === "other"))
    this.syncDate("other")
  }

  syncDate(mode) {
    if (!this.hasDateHintTarget) return
    const active = mode || this.datePillTargets.find((p) => p.classList.contains("pill--active"))?.dataset.dateMode || "today"
    if (active === "today") this.dateHintTarget.textContent = this.hasDateTodayValue ? this.dateTodayValue : ""
    else if (active === "yesterday") this.dateHintTarget.textContent = this.hasDateYesterdayValue ? this.dateYesterdayValue : ""
    else this.dateHintTarget.textContent = this.hasDateInputTarget && this.dateInputTarget.value ? this.#fmtDate(this.dateInputTarget.value) : ""
  }

  #iso(offsetDays) {
    const d = new Date()
    d.setDate(d.getDate() + offsetDays)
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`
  }

  #fmtDate(value) {
    const [y, m, d] = value.split("-")
    return `${d}/${m}/${y}`
  }

  // A transfer doesn't change your situation, so instead of a projection we show
  // both accounts' current balances once they're picked.
  syncBalances() {
    if (!this.hasBalancesTarget) return

    const nameOf = (field) => this.element.querySelector(`[name="transaction[${field}]"]`)?.value?.trim()
    const from = nameOf("from_account_name")
    const to = nameOf("to_account_name")
    const parts = []
    const fmt = (n) => `${Number(n).toLocaleString(this.hasLocaleValue ? this.localeValue : undefined)} ${this.currencyValue}`
    if (from && this.balancesValue[from] != null) parts.push(`${from} ${fmt(this.balancesValue[from])}`)
    if (to && this.balancesValue[to] != null) parts.push(`${to} ${fmt(this.balancesValue[to])}`)

    if (parts.length) {
      this.balancesTarget.textContent = parts.join(" · ")
      this.balancesTarget.hidden = false
    } else {
      this.balancesTarget.hidden = true
    }
  }

  // The submit button carries the amount ("Save 24.90 €") and names what's
  // missing while it's blank ("Enter an amount").
  syncCta() {
    if (!this.hasCtaTarget || !this.hasCtaTemplateValue) return

    const raw = this.hasAmountTarget ? parseFloat(this.amountTarget.value) : NaN
    if (raw > 0) {
      const value = `${raw.toLocaleString(this.hasLocaleValue ? this.localeValue : undefined)} ${this.currencyValue}`
      this.ctaTarget.textContent = this.ctaTemplateValue.replace("%{amount}", value)
      this.ctaTarget.disabled = false
    } else {
      this.ctaTarget.textContent = this.ctaEmptyValue
    }
  }

  // When picking a category suggestion replaces what the user typed ("carrefour" →
  // "Provisions"), keep the typed text in the description so nothing is lost. Bound via
  // data-action on the form root; only reacts to the category field.
  keepTypedText(event) {
    const field = event.target
    if (!field.name || !field.name.includes("transaction_type_name")) return

    const typed = (field.dataset.typedQuery || "").trim()
    delete field.dataset.typedQuery
    if (!typed) return

    // Typing the category's own name (or creating it as a custom type) carries no extra info.
    const value = (event.detail?.value || "").toLowerCase()
    if (value.includes(typed.toLowerCase())) return

    const description = this.element.querySelector('[name="transaction[description]"]')
    if (description && !description.value) description.value = typed
  }

  toggleDetails(event) {
    event.preventDefault()
    const optionalFields = this.optionalFieldsTarget
    const toggleButton = this.toggleButtonTarget

    if (optionalFields.classList.contains('hidden')) {
      optionalFields.classList.remove('hidden')
      toggleButton.textContent = toggleButton.dataset.hideText || 'Hide details'
    } else {
      optionalFields.classList.add('hidden')
      toggleButton.textContent = toggleButton.dataset.showText || 'More details'
    }
  }
}
