import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="swipe"
// Swipe a review line left to reveal its "Ignorer" action, the shortcut iOS and
// Android lists use. Only a clearly horizontal drag counts, so scrolling the list never
// triggers it; the tap that ends a drag never opens the line.
export default class extends Controller {
  static targets = ["content"]
  static ACTION_WIDTH = 96
  static THRESHOLD = 48

  connect() {
    this.onDown = this.down.bind(this)
    this.onMove = this.move.bind(this)
    this.onUp = this.up.bind(this)
    this.contentTarget.addEventListener("pointerdown", this.onDown)
  }

  disconnect() {
    this.contentTarget.removeEventListener("pointerdown", this.onDown)
    this.release()
  }

  down(event) {
    if (event.pointerType === "mouse" && event.button !== 0) return
    this.startX = event.clientX
    this.startY = event.clientY
    this.base = this.open ? -this.constructor.ACTION_WIDTH : 0
    this.dragging = false
    this.dragged = false
    window.addEventListener("pointermove", this.onMove)
    window.addEventListener("pointerup", this.onUp)
    window.addEventListener("pointercancel", this.onUp)
  }

  move(event) {
    const dx = event.clientX - this.startX
    const dy = event.clientY - this.startY
    if (!this.dragging) {
      if (Math.abs(dx) < 8 || Math.abs(dx) < Math.abs(dy) * 1.5) {
        if (Math.abs(dy) > 8) this.release()
        return
      }
      this.dragging = true
      this.closeOthers()
    }
    this.dragged = true
    const x = Math.min(0, Math.max(-this.constructor.ACTION_WIDTH * 1.2, this.base + dx))
    this.translate(x, false)
  }

  up(event) {
    this.release()
    if (!this.dragging) return
    const dx = event.clientX - this.startX
    this.setOpen(this.base + dx < -this.constructor.THRESHOLD)
  }

  // A drag ends with a click on the label: swallow it, and a tap on an open line closes it.
  guard(event) {
    if (this.dragged || this.open) {
      event.preventDefault()
      event.stopImmediatePropagation()
      this.dragged = false
      if (this.open && !this.dragging) this.setOpen(false)
    }
  }

  setOpen(open) {
    this.open = open
    this.element.classList.toggle("is-swiped", open)
    this.translate(open ? -this.constructor.ACTION_WIDTH : 0, true)
  }

  translate(x, animate) {
    this.contentTarget.style.transition = animate ? "" : "none"
    this.contentTarget.style.transform = x ? `translateX(${x}px)` : ""
  }

  closeOthers() {
    document.querySelectorAll("[data-controller~='swipe'].is-swiped").forEach((el) => {
      if (el === this.element) return
      const other = this.application.getControllerForElementAndIdentifier(el, "swipe")
      other?.setOpen(false)
    })
  }

  release() {
    window.removeEventListener("pointermove", this.onMove)
    window.removeEventListener("pointerup", this.onUp)
    window.removeEventListener("pointercancel", this.onUp)
  }
}
