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
    if (this.frameTarget.children.length > 0) this.open()
  }

  // A form saved in the sheet redirects to a full page. That page carries the layout's
  // empty <turbo-frame id="modal">, so Turbo renders nothing into the sheet. The response
  // is the whole page (our layouts ignore turbo-rails' frame layout): render it as the
  // page visit the controller asked for, instead of fetching it a second time.
  async frameRendered(event) {
    if (event.target !== this.frameTarget || !this.isOpen) return
    const { fetchResponse } = event.detail
    if (!fetchResponse || !fetchResponse.redirected || event.target.children.length > 0) return

    const responseHTML = await fetchResponse.responseHTML
    this.close()
    window.Turbo.visit(fetchResponse.location, {
      response: { redirected: true, statusCode: fetchResponse.statusCode, responseHTML }
    })
  }

  // Same thing when the redirect target lacks the frame the form was submitted in (the
  // nested "transaction_form" frame): Turbo hands us the response, visit it as a page.
  frameMissing(event) {
    if (!this.isOpen) return

    event.preventDefault()
    this.close()
    event.detail.visit(event.detail.response)
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
