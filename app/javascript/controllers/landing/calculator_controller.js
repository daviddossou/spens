import { Controller } from "@hotwired/stimulus"

// Savings calculator: monthly = income × pct / 100, projections ×12/36/120.
// Amounts stay in whatever currency the visitor thinks in; no conversion.
export default class extends Controller {
  static targets = ["income", "slider", "pct", "monthly", "y1", "y3", "y10"]

  connect() {
    this.compute()
  }

  compute() {
    const digits = this.incomeTarget.value.replace(/[^\d]/g, "")
    if (digits !== this.incomeTarget.value) this.incomeTarget.value = digits

    const income = parseInt(digits, 10) || 0
    const pct = parseInt(this.sliderTarget.value, 10)
    const monthly = Math.round((income * pct) / 100)

    this.pctTarget.textContent = `${pct} %`
    this.monthlyTarget.textContent = this.format(monthly)
    this.y1Target.textContent = this.format(monthly * 12)
    this.y3Target.textContent = this.format(monthly * 36)
    this.y10Target.textContent = this.format(monthly * 120)
  }

  format(n) {
    return n.toLocaleString(document.documentElement.lang === "en" ? "en" : "fr-FR")
  }
}
