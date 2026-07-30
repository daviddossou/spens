import { Controller } from "@hotwired/stimulus"

// Toggles a class while a position:sticky element is pinned to its top offset,
// so it can cast a shadow over the content scrolling beneath it.
// Connects to data-controller="sticky" with data-sticky-stuck-class.
export default class extends Controller {
  static classes = ["stuck"]

  connect() {
    const top = parseFloat(getComputedStyle(this.element).top) || 0

    // Watching the element against a root shrunk by (top + 1)px: once pinned,
    // its top edge pokes above that line and the ratio drops below 1.
    this.observer = new IntersectionObserver(
      ([entry]) => {
        this.element.classList.toggle(this.stuckClass, entry.intersectionRatio < 1)
      },
      { threshold: [1], rootMargin: `-${top + 1}px 0px 0px 0px` }
    )
    this.observer.observe(this.element)
  }

  disconnect() {
    this.observer?.disconnect()
  }
}
