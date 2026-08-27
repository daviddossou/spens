import { Controller } from "@hotwired/stimulus"
import { formatMoney } from "lib/money"

// Drives the budget-line form's advanced settings: frequency segments, the
// "no end / until a date" choice, the rollover toggle, and — crucially — the
// live summary the collapsed "Edit" line shows, so you know the active settings
// without opening it. Also keeps the amount's "a month / a quarter" label in sync.
export default class extends Controller {
  static targets = [
    "frequency", "periodLabel", "freqSeg",
    "endSeg", "endField", "endInput",
    "rollover", "summaryMain", "summaryRollover",
    "amount", "cta", "rolloverExample"
  ]
  static values = {
    periodLabels: Object,
    periodShort: Object,
    summaryFreq: Object,
    summaryEnd: Object,
    summaryRollover: Object,
    currency: String,
    locale: String,
    ctaTemplate: String,
    ctaEmpty: String,
    rolloverExample: String,
    rolloverEmpty: String,
    nextMonth: String
  }

  connect() {
    this.render()
  }

  setFrequency(event) {
    const freq = event.currentTarget.dataset.frequency
    if (this.hasFrequencyTarget) this.frequencyTarget.value = freq
    this.freqSegTargets.forEach((seg) => {
      seg.classList.toggle("seg--active", seg.dataset.frequency === freq)
    })
    this.render()
  }

  setEnd(event) {
    const dated = event.currentTarget.dataset.end === "date"
    this.endSegTargets.forEach((seg) => {
      seg.classList.toggle("pill--active", (seg.dataset.end === "date") === dated)
    })
    if (this.hasEndFieldTarget) this.endFieldTarget.classList.toggle("hidden", !dated)
    if (!dated && this.hasEndInputTarget) this.endInputTarget.value = ""
    this.render()
  }

  syncSummary() {
    this.render()
  }

  render() {
    const freq = (this.hasFrequencyTarget && this.frequencyTarget.value) || "monthly"

    if (this.hasPeriodLabelTarget) {
      this.periodLabelTarget.textContent = this.periodLabelsValue[freq] || this.periodLabelsValue.monthly || ""
    }

    if (this.hasSummaryMainTarget) {
      const freqText = this.summaryFreqValue[freq] || this.summaryFreqValue.monthly || ""
      const hasDate = this.hasEndInputTarget && this.endInputTarget.value
      const endText = hasDate
        ? (this.summaryEndValue.date || "%{date}").replace("%{date}", this.#formatDate(this.endInputTarget.value))
        : (this.summaryEndValue.never || "")
      this.summaryMainTarget.textContent = `${freqText}, ${endText}`
    }

    if (this.hasSummaryRolloverTarget && this.hasRolloverTarget) {
      this.summaryRolloverTarget.textContent = this.rolloverTarget.checked
        ? this.summaryRolloverValue.on
        : this.summaryRolloverValue.off
    }

    // Rollover sub-line: a concrete figure once an amount is entered, showing
    // what carries into next month; otherwise the plain concept.
    if (this.hasRolloverExampleTarget) {
      const raw = this.hasAmountTarget ? parseFloat(this.amountTarget.value) : NaN
      if (raw > 0 && this.hasRolloverExampleValue) {
        const loc = this.hasLocaleValue ? this.localeValue : undefined
        const planned = raw
        const spent = Math.round(planned * 0.625)
        const carried = planned + (planned - spent)
        const fmt = (n) => formatMoney(n, this.currencyValue, loc)
        this.rolloverExampleTarget.textContent = this.rolloverExampleValue
          .replace("%{planned}", fmt(planned))
          .replace("%{spent}", fmt(spent))
          .replace("%{carried}", fmt(carried))
          .replace("%{month}", this.hasNextMonthValue ? this.nextMonthValue : "")
      } else {
        this.rolloverExampleTarget.textContent = this.hasRolloverEmptyValue ? this.rolloverEmptyValue : ""
      }
    }

    // The CTA carries the amount + cadence: "Add 80 €/month to plan".
    if (this.hasCtaTarget && this.hasCtaTemplateValue) {
      const raw = this.hasAmountTarget ? parseFloat(this.amountTarget.value) : NaN
      if (raw > 0) {
        const short = this.periodShortValue[freq] || this.periodShortValue.monthly || ""
        const value = `${formatMoney(raw, this.currencyValue, this.hasLocaleValue ? this.localeValue : undefined)}/${short}`
        this.ctaTarget.textContent = this.ctaTemplateValue.replace("%{value}", value)
      } else {
        this.ctaTarget.textContent = this.ctaEmptyValue
      }
    }
  }

  #formatDate(value) {
    const parts = value.split("-")
    if (parts.length !== 3) return value
    const [year, month, day] = parts
    return `${day}/${month}/${year}`
  }
}
