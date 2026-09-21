import { Controller } from "@hotwired/stimulus"

// Savings calculator: monthly = income × pct / 100, projections ×12/36/120.
// Amounts stay in whatever currency the visitor thinks in; no conversion.
// Only the targets a page renders are filled (onboarding shows 1 and 3 years).
export default class extends Controller {
  static targets = ["income", "slider", "pct", "monthly", "y1", "y3", "y10"]
  static values = { grouped: Boolean }

  connect() {
    this.compute()
  }

  compute() {
    const digits = this.incomeTarget.value.replace(/[^\d]/g, "")
    this.writeIncome(digits)

    const income = parseInt(digits, 10) || 0
    const pct = parseInt(this.sliderTarget.value, 10)
    const monthly = Math.round((income * pct) / 100)

    this.pctTarget.textContent = `${pct} %`
    this.paintSlider()
    this.fill("monthly", monthly)
    this.fill("y1", monthly * 12)
    this.fill("y3", monthly * 36)
    this.fill("y10", monthly * 120)
  }

  // Webkit has no native "filled" track; the stylesheet paints it from --fill.
  paintSlider() {
    const { min, max, value } = this.sliderTarget
    const span = (max || 100) - (min || 0)
    this.sliderTarget.style.setProperty("--fill", `${((value - (min || 0)) / span) * 100}%`)
  }

  fill(name, amount) {
    if (this.targets.has(name)) this.targets.find(name).textContent = this.format(amount)
  }

  // Grouped mode shows "150 000" while typing and keeps the caret in place.
  writeIncome(digits) {
    const input = this.incomeTarget
    const shown = this.groupedValue && digits ? this.format(parseInt(digits, 10)) : digits
    if (shown === input.value) return

    const caretDigits = input.value.slice(0, input.selectionStart ?? input.value.length).replace(/[^\d]/g, "").length
    input.value = shown
    if (!this.groupedValue || document.activeElement !== input) return

    let caret = 0
    for (let seen = 0; caret < shown.length && seen < caretDigits; caret++) {
      if (/\d/.test(shown[caret])) seen++
    }
    input.setSelectionRange(caret, caret)
  }

  // French groups with a narrow no-break space, too thin to read in Geist: widen it.
  format(n) {
    return n.toLocaleString(document.documentElement.lang === "en" ? "en" : "fr-FR").replace(/\u202f/g, "\u00a0")
  }
}
