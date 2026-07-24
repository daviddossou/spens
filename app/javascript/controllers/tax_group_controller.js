import { Controller } from "@hotwired/stimulus"

// One tbody per parent category: the chevron on the parent row shows/hides its children.
export default class extends Controller {
  toggle() {
    this.element.classList.toggle("admin-taxgroup--open")
  }
}
