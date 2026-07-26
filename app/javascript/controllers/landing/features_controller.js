import { Controller } from "@hotwired/stimulus"

// Feature showcase: clicking a card plays its demo video — in the sticky side
// panel on desktop, inline inside the card (accordion) on mobile. Nothing
// (video or poster) loads before its card is first activated. WebM first,
// MP4 fallback for Safari. With reduced motion, only the poster is shown.
export default class extends Controller {
  static targets = ["card", "cardVideo", "panelVideo"]

  connect() {
    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.activate(0)
  }

  select(event) {
    this.activate(this.cardTargets.indexOf(event.currentTarget))
  }

  activate(index) {
    const card = this.cardTargets[index]
    if (!card) return

    this.cardTargets.forEach((c, i) => {
      const active = i === index
      c.classList.toggle("is-active", active)
      c.setAttribute("aria-expanded", active)
    })

    // Mobile accordion video
    this.cardVideoTargets.forEach((video, i) => {
      if (i === index) {
        this.load(video, card)
        this.play(video)
      } else {
        video.pause()
      }
    })

    // Desktop panel: crossfade then swap
    const panel = this.panelVideoTarget
    if (panel.dataset.current !== String(index)) {
      panel.dataset.current = String(index)
      const swap = () => {
        this.load(panel, card, { force: true })
        panel.onloadeddata = () => panel.classList.remove("is-fading")
        panel.onerror = () => panel.classList.remove("is-fading")
        this.play(panel)
      }
      if (panel.querySelector("source")) {
        panel.classList.add("is-fading")
        setTimeout(swap, 120)
      } else {
        swap()
      }
    }
  }

  // Attaches poster + sources the first time (or replaces them when force).
  load(video, card, { force = false } = {}) {
    if (!force && video.querySelector("source")) return
    video.innerHTML = ""
    video.poster = card.dataset.poster
    const webm = document.createElement("source")
    webm.src = card.dataset.webm
    webm.type = "video/webm"
    const mp4 = document.createElement("source")
    mp4.src = card.dataset.mp4
    mp4.type = "video/mp4"
    video.append(webm, mp4)
    video.load()
  }

  play(video) {
    if (this.reducedMotion) return // poster only
    video.play().catch(() => {})
  }
}
