import { Controller } from "@hotwired/stimulus"

// Naming a person or an account is a real text entry — the keyboard belongs
// here (Tour 30d). So the suggestion is a single row of chips glued under the
// field, which no keyboard can cover, never a vertical list that one would.
export default class extends Controller {
  static targets = ["input", "chips"]
  static values = { suggestions: Array, limit: Number, seeAllLabel: String, seeAllTitle: String }

  connect() {
    this.render()
  }

  render() {
    const typed = this.inputTarget.value.trim().toLowerCase()
    const limit = this.hasLimitValue ? this.limitValue : 3
    const matches = this.suggestionsValue
      .filter((name) => !typed || name.toLowerCase().includes(typed))
      .filter((name) => name.toLowerCase() !== typed)
      .slice(0, limit)

    const chips = matches.map((name) => this.chip(name))

    // Chips are a shortcut over the recent few. Past that, the list has to stay
    // reachable — it is the only place in the app you cannot see what exists
    // otherwise (Tour 32b-5). Under the limit they already show everyone.
    if (this.hasSeeAllLabelValue && this.suggestionsValue.length > limit) {
      chips.push(this.seeAllChip())
    }

    this.chipsTarget.replaceChildren(...chips)
    this.chipsTarget.hidden = chips.length === 0
  }

  seeAllChip() {
    const button = document.createElement("button")
    button.type = "button"
    button.className = "name-chip name-chip--all"
    button.textContent = this.seeAllLabelValue
    button.addEventListener("click", () => {
      const el = document.getElementById("picker-layer")
      const layer = el && this.application.getControllerForElementAndIdentifier(el, "picker-layer")
      layer?.present({
        title: this.seeAllTitleValue,
        rows: this.suggestionsValue.map((name) => ({ value: name, label: name })),
        selected: this.inputTarget.value,
        onSelect: (row) => {
          this.inputTarget.value = row.value
          this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
          this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
          this.render()
        }
      })
    })
    return button
  }

  chip(name) {
    const button = document.createElement("button")
    button.type = "button"
    button.className = "name-chip"
    button.textContent = name
    button.addEventListener("click", () => {
      this.inputTarget.value = name
      this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
      this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
      this.render()
    })
    return button
  }
}
