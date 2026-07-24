import { Controller } from "@hotwired/stimulus"

// Upgrades the <select> inside a chip popover to a searchable-select only when the
// popover first opens — the alias dictionary renders ~1000 chips, and eager TomSelect
// on every one would stall the page.
export default class extends Controller {
  connect() {
    this.element.addEventListener("toggle", this.upgrade)
  }

  disconnect() {
    this.element.removeEventListener("toggle", this.upgrade)
  }

  upgrade = () => {
    if (!this.element.open || this.upgraded) return
    this.upgraded = true
    const select = this.element.querySelector("select")
    if (select) select.setAttribute("data-controller", "searchable-select")
  }
}
