import { Controller } from "@hotwired/stimulus"
import { formatMoney } from "lib/money"

// Drives the debt branch of the budget-line form. The money direction is two
// written-out sentences ("I repay Georges" / "Georges repays me") with the
// monthly effect shown live; when the app already knows the balance it states it
// ("You owe 900 to Georges"); once you set a monthly amount it works out when the
// debt clears and ends the recurring line there. The person field notifies us via change.
export default class extends Controller {
  static targets = [
    "kindInput", "card", "cardTitle", "cardEffect",
    "balance", "settled"
  ]
  static values = {
    kindsByName: Object,
    summaries: Object,
    currency: String,
    startsOn: String,
    locale: String,
    currentName: String,
    labels: Object
  }

  connect() {
    this.form = this.element.closest(".budget-item-form")
    this.amountInput = this.form?.querySelector(".budget-amount__input")
    if (this.amountInput) {
      this.onAmount = () => this.render()
      this.amountInput.addEventListener("input", this.onAmount)
    }
    this.name = this.currentNameValue || ""
    this.render()
  }

  disconnect() {
    if (this.amountInput && this.onAmount) this.amountInput.removeEventListener("input", this.onAmount)
  }

  onPersonChange(event) {
    this.name = (event.detail?.value ?? event.target?.value ?? "").trim()
    const kinds = this.kindsByNameValue[this.name.toLowerCase()]
    if (kinds && kinds.length === 1) this.setKind(kinds[0])
    this.render()
  }

  selectCard(event) {
    this.setKind(event.currentTarget.dataset.kind)
    this.render()
  }

  setKind(kind) {
    this.kindInputTarget.value = kind
    this.cardTargets.forEach((card) => {
      const selected = card.dataset.kind === kind
      card.classList.toggle("debt-card--selected", selected)
      card.setAttribute("aria-checked", String(selected))
    })
  }

  render() {
    const name = this.name.trim() || this.labelsValue.someone
    const amount = this.#amount()
    const amountText = formatMoney(amount > 0 ? amount : 0, this.currencyValue, this.localeValue || "fr")

    this.cardTitleTargets.forEach((el) => {
      const tpl = this.labelsValue[el.closest(".debt-card").dataset.title]
      el.textContent = tpl.replace("%{name}", name)
    })
    this.cardEffectTargets.forEach((el) => {
      const tpl = this.labelsValue[el.closest(".debt-card").dataset.effect]
      el.textContent = tpl.replace("%{amount}", amountText)
    })

    const summary = this.summariesValue[this.name.trim().toLowerCase()]
    if (summary && summary.balance > 0) {
      const balText = formatMoney(summary.balance, this.currencyValue, this.localeValue || "fr")
      const tpl = summary.direction === "borrowed" ? this.labelsValue.you_owe : this.labelsValue.owes_you
      this.balanceTarget.textContent = tpl.replace("%{amount}", balText).replace("%{name}", name)
      this.balanceTarget.hidden = false

      // With a balance and a monthly amount, work out when it clears and end the
      // recurring line there on its own.
      if (amount > 0) {
        const clears = this.#clearsOn(summary.balance, amount)
        this.#applyEnd(clears.iso)
        if (this.hasSettledTarget) {
          this.settledTarget.textContent = this.labelsValue.settled.replace("%{date}", clears.label)
          this.settledTarget.hidden = false
        }
      } else if (this.hasSettledTarget) {
        this.settledTarget.hidden = true
      }
    } else {
      this.balanceTarget.hidden = true
      if (this.hasSettledTarget) this.settledTarget.hidden = true
    }
  }

  #amount() {
    const value = parseFloat(this.amountInput?.value)
    return value > 0 ? value : 0
  }

  // The month the debt is cleared, paying `amount` each month against `balance`.
  #clearsOn(balance, amount) {
    const payments = Math.max(1, Math.ceil(balance / amount))
    const [year, month] = this.startsOnValue.split("-").map(Number)
    const end = new Date(year, (month - 1) + (payments - 1), 1)
    const iso = `${end.getFullYear()}-${String(end.getMonth() + 1).padStart(2, "0")}-01`
    const label = end.toLocaleDateString(this.localeValue || "fr", { month: "long", year: "numeric" })
    return { iso, label }
  }

  // Set the recurring line's end date on the shared form + reflect it in the
  // "until a date" control and the collapsed summary.
  #applyEnd(iso) {
    const endInput = this.form?.querySelector('[data-budget-line-target="endInput"]')
    if (!endInput || endInput.value === iso) return

    endInput.value = iso
    endInput.dispatchEvent(new Event("input", { bubbles: true }))
    this.form.querySelector('[data-budget-line-target="endField"]')?.classList.remove("hidden")
    this.form.querySelectorAll('[data-budget-line-target="endSeg"]').forEach((seg) => {
      seg.classList.toggle("pill--active", seg.dataset.end === "date")
    })
  }
}
