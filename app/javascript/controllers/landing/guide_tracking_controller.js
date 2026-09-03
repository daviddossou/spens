import { Controller } from "@hotwired/stimulus"

// Guide-page Meta events that only the browser can observe. Each fires once,
// on both channels with the same server-issued event_id:
// - ViewContent: 30 s on page OR the Awa extract section scrolled into view
// - Lead: click on a download CTA (content_name = hero | final)
// The pixel call happens here; the beacon asks the server to double it via CAPI
// (the server only accepts event keys it issued ids for in this session).
export default class extends Controller {
  static targets = ["extract"]
  static values = { url: String, events: Object }

  connect() {
    this.sent = new Set()
    if (!this.eventsValue.view_content) return

    this.timer = setTimeout(() => this.viewContent(), 30000)
    if (this.hasExtractTarget && "IntersectionObserver" in window) {
      this.observer = new IntersectionObserver((entries) => {
        if (entries.some((e) => e.isIntersecting)) this.viewContent()
      }, { threshold: 0.4 })
      this.observer.observe(this.extractTarget)
    }
  }

  disconnect() {
    clearTimeout(this.timer)
    this.observer?.disconnect()
  }

  viewContent() {
    this.#send("view_content", "ViewContent", {})
    this.observer?.disconnect()
    clearTimeout(this.timer)
  }

  lead(event) {
    const placement = event.params.placement
    this.#send(`lead_${placement}`, "Lead", { content_name: placement })
  }

  #send(key, name, data) {
    if (this.sent.has(key)) return
    this.sent.add(key)

    const eventId = this.eventsValue[key]
    if (window.fbq && eventId) window.fbq("track", name, data, { eventID: eventId })

    const token = document.querySelector('meta[name="csrf-token"]')?.content
    fetch(this.urlValue, {
      method: "POST",
      keepalive: true,
      headers: { "Content-Type": "application/json", "X-CSRF-Token": token },
      body: JSON.stringify({ event: key })
    }).catch(() => {})
  }
}
