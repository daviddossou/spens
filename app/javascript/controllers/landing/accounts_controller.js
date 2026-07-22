import { Controller } from "@hotwired/stimulus"

// Simulated account rows: add/remove lines (min 1), live total. Nothing is persisted.
export default class extends Controller {
  static targets = ["rows", "row", "template", "balance", "total"]

  connect() {
    this.compute()
  }

  add() {
    this.rowsTarget.appendChild(this.templateTarget.content.cloneNode(true))
    this.compute()
  }

  remove(event) {
    if (this.rowTargets.length <= 1) return
    event.currentTarget.closest("[data-landing--accounts-target~='row']").remove()
    this.compute()
  }

  compute() {
    let total = 0
    this.balanceTargets.forEach((input) => {
      const digits = input.value.replace(/[^\d]/g, "")
      if (digits !== input.value) input.value = digits
      total += parseInt(digits, 10) || 0
    })
    this.totalTarget.textContent = total.toLocaleString(
      document.documentElement.lang === "en" ? "en" : "fr-FR"
    )
  }
}
