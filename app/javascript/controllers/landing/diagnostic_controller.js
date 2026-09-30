import { Controller } from "@hotwired/stimulus"

// Self-diagnostic checklist: toggle cards, count them, swap the recap message per tier.
// The checked cards' goals are read by landing--handoff when a sign-up link is clicked.
export default class extends Controller {
  static targets = ["card", "count", "title", "line"]
  static values = { tiers: Object }

  toggle(event) {
    const card = event.currentTarget
    const checked = card.classList.toggle("is-checked")
    card.setAttribute("aria-pressed", checked)
    this.render()
  }

  render() {
    const checked = this.cardTargets.filter((c) => c.classList.contains("is-checked"))
    const n = checked.length
    const tier = n === 0 ? "none" : n <= 2 ? "low" : n <= 4 ? "mid" : "high"
    this.countTarget.textContent = n
    this.titleTarget.textContent = this.tiersValue[tier].title
    this.lineTarget.textContent = this.tiersValue[tier].line
  }
}
