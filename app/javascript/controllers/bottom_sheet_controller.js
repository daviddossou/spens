import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "backdrop", "frame"]

  connect() {
    this._onKeydown = this._onKeydown.bind(this)
  }

  // Called when the turbo frame finishes loading content
  frameLoaded(event) {
    // Only react to loads on the modal frame itself, not nested frames
    if (event.target !== this.frameTarget) return

    if (this.frameTarget.children.length > 0) {
      this.open()
    }
  }

  // Called when a frame response doesn't contain the expected frame ID.
  // This happens after a successful form submission + redirect — the
  // redirected page won't have <turbo-frame id="modal"> or "transaction_form".
  frameMissing(event) {
    if (!this.isOpen) return

    event.preventDefault()
    this.close()

    // Navigate to the response URL with a full page visit
    const response = event.detail.response
    setTimeout(() => {
      window.Turbo.visit(response.url, { action: "replace" })
    }, 300)
  }

  open() {
    this.element.setAttribute("data-state", "open")
    document.body.classList.add("bottom-sheet-open")
    document.addEventListener("keydown", this._onKeydown)
  }

  close() {
    this.element.removeAttribute("data-state")
    document.body.classList.remove("bottom-sheet-open")
    document.removeEventListener("keydown", this._onKeydown)

    // Clear frame content after the close animation completes
    setTimeout(() => {
      if (!this.isOpen) {
        this.frameTarget.removeAttribute("src")
        this.frameTarget.innerHTML = ""
      }
    }, 350)
  }

  _onKeydown(event) {
    if (event.key === "Escape" && this.isOpen) {
      event.preventDefault()
      this.close()
    }
  }

  get isOpen() {
    return this.element.getAttribute("data-state") === "open"
  }

  disconnect() {
    document.removeEventListener("keydown", this._onKeydown)
    document.body.classList.remove("bottom-sheet-open")
  }
}
