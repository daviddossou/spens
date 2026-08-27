import { Controller } from "@hotwired/stimulus"

// The debt branch of the transaction form: pick a person, then choose from four
// written-out sentences (lend / get repaid / borrow / repay). Each card writes
// the hidden `kind` and `direction` the backend consumes, shows the monthly
// effect live, and the resulting balance with that person. Hidden until a person
// is chosen — one question at a time.
export default class extends Controller {
  static targets = [
    "kindInput", "directionInput", "cards", "card", "cardTitle", "cardEffect",
    "after", "afterLabel", "afterValue", "feeField"
  ]
  static values = {
    debtsByName: Object,
    balances: Object,
    currency: String,
    locale: String,
    contactName: String,
    locked: Boolean,
    labels: Object
  }

  connect() {
    if (!this.hasCardsTarget) return

    this.name = this.contactNameValue || ""
    this.amountInput = this.element.querySelector(".budget-amount__input")
    if (this.amountInput) {
      this.onAmount = () => this.render()
      this.amountInput.addEventListener("input", this.onAmount)
    }
    this.render()
    this.syncFee()
  }

  disconnect() {
    if (this.amountInput && this.onAmount) this.amountInput.removeEventListener("input", this.onAmount)
  }

  onPersonChange(event) {
    this.name = (event.detail?.value ?? event.target?.value ?? "").trim()
    this.render()
  }

  selectCard(event) {
    const card = event.currentTarget
    this.kindInputTarget.value = card.dataset.kind
    this.directionInputTarget.value = card.dataset.direction
    this.cardTargets.forEach((c) => {
      const on = c === card
      c.classList.toggle("debt-card--selected", on)
      c.setAttribute("aria-checked", String(on))
    })
    this.syncFee()
    this.render()
  }

  render() {
    const visible = this.lockedValue || this.name.trim().length > 0
    this.cardsTarget.classList.toggle("hidden", !visible)

    const name = this.name.trim() || this.labelsValue.someone
    const amount = this.#amount()
    const amountText = this.#money(amount)
    const bal = this.balancesValue[this.name.trim().toLowerCase()] || { lent: 0, borrowed: 0 }

    this.cardTargets.forEach((card) => {
      const v = card.dataset.variant
      const title = card.querySelector('[data-debt-fields-target="cardTitle"]')
      const effect = card.querySelector('[data-debt-fields-target="cardEffect"]')
      if (title) title.textContent = this.labelsValue.titles[v].replace("%{name}", name)
      if (effect) {
        const result = v === "lent_out" ? bal.lent + amount : v === "borrowed_in" ? bal.borrowed + amount : null
        effect.textContent = this.labelsValue.effects[v]
          .replace("%{amount}", amountText)
          .replace("%{name}", name)
          .replace("%{result}", result == null ? "" : this.#money(result))
      }
    })

    this.#renderAfter(name, amount, bal)
  }

  #renderAfter(name, amount, bal) {
    if (!this.hasAfterTarget) return
    const selected = this.cardTargets.find((c) => c.classList.contains("debt-card--selected"))
    if (!selected || amount <= 0) {
      this.afterTarget.hidden = true
      return
    }

    let lent = bal.lent
    let borrowed = bal.borrowed
    switch (selected.dataset.variant) {
      case "lent_out": lent += amount; break
      case "lent_in": lent = Math.max(0, lent - amount); break
      case "borrowed_in": borrowed += amount; break
      case "borrowed_out": borrowed = Math.max(0, borrowed - amount); break
    }
    const net = lent - borrowed

    this.afterLabelTarget.textContent = this.labelsValue.after_label.replace("%{name}", name)
    if (net > 0) this.afterValueTarget.textContent = this.labelsValue.after_they_owe.replace("%{name}", name).replace("%{amount}", this.#money(net))
    else if (net < 0) this.afterValueTarget.textContent = this.labelsValue.after_you_owe.replace("%{amount}", this.#money(-net))
    else this.afterValueTarget.textContent = this.labelsValue.after_settled
    this.afterTarget.hidden = false
  }

  // A fee only applies to money leaving (debt_out).
  syncFee() {
    if (!this.hasFeeFieldTarget) return
    this.feeFieldTarget.classList.toggle("hidden", this.kindInputTarget.value !== "debt_out")
  }

  #amount() {
    const v = parseFloat(this.amountInput?.value)
    return v > 0 ? v : 0
  }

  #money(n) {
    return `${Number(n).toLocaleString(this.hasLocaleValue ? this.localeValue : undefined)} ${this.currencyValue}`
  }
}
