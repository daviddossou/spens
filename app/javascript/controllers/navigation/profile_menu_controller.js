import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "backdrop"]

  connect() {
    this.close = this.close.bind(this)
  }

  toggle(event) {
    event.stopPropagation()

    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.menuTarget.setAttribute("data-visible", "")
    this.backdropTarget.setAttribute("data-visible", "")
    document.addEventListener("keydown", this._onKeydown)
  }

  close() {
    this.menuTarget.removeAttribute("data-visible")
    this.backdropTarget.removeAttribute("data-visible")
    document.removeEventListener("keydown", this._onKeydown)
  }

  _onKeydown = (event) => {
    if (event.key === "Escape") {
      this.close()
    }
  }

  get isOpen() {
    return this.menuTarget.hasAttribute("data-visible")
  }

  disconnect() {
    document.removeEventListener("keydown", this._onKeydown)
  }
}
