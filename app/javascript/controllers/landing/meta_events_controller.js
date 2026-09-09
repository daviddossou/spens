import { Controller } from "@hotwired/stimulus"

// Marketing-page events that only the browser can observe, sent three ways:
// Meta pixel (when consented), a beacon that doubles them through the CAPI
// with the same server-issued event_id, and PostHog for internal ad analysis
// (posthog-js attaches utm_* from the URL by itself).
//
// - ViewContent: 30 s on page OR the milestone section scrolled into view
// - lead: guide download CTA (content_name = hero | final)
// - signup: sign-up CTA on the landing (content_name = placement)
// Each fires once per page view; the server only accepts event keys it issued
// ids for in this session.
export default class extends Controller {
  static targets = ["milestone"]
  static values = { url: String, events: Object, page: String }

  connect() {
    this.sent = new Set()
    if (!this.eventsValue.view_content) return

    this.timer = setTimeout(() => this.viewContent(), 30000)
    if (this.hasMilestoneTarget && "IntersectionObserver" in window) {
      this.observer = new IntersectionObserver((entries) => {
        if (entries.some((e) => e.isIntersecting)) this.viewContent()
      }, { threshold: 0.4 })
      this.observer.observe(this.milestoneTarget)
    }
  }

  disconnect() {
    clearTimeout(this.timer)
    this.observer?.disconnect()
  }

  viewContent() {
    this.#send("view_content", { fbq: ["track", "ViewContent", {}], posthog: [`${this.pageValue}_view_content`, {}] })
    this.observer?.disconnect()
    clearTimeout(this.timer)
  }

  lead(event) {
    const placement = event.params.placement
    this.#send(`lead_${placement}`, {
      fbq: ["track", "Lead", { content_name: placement }],
      posthog: ["guide_download", { placement }]
    })
  }

  signup(event) {
    const placement = event.params.placement
    this.#send("signup_start", {
      fbq: ["trackCustom", "spens_signup_start", { content_name: placement }],
      posthog: ["signup_start", { placement }],
      placement
    })
  }

  #send(key, { fbq, posthog, placement }) {
    if (this.sent.has(key)) return
    this.sent.add(key)

    const eventId = this.eventsValue[key]
    if (window.fbq && eventId) window.fbq(fbq[0], fbq[1], fbq[2], { eventID: eventId })
    if (window.posthog?.capture) window.posthog.capture(posthog[0], posthog[1])

    const token = document.querySelector('meta[name="csrf-token"]')?.content
    fetch(this.urlValue, {
      method: "POST",
      keepalive: true,
      headers: { "Content-Type": "application/json", "X-CSRF-Token": token },
      body: JSON.stringify({ event: key, placement })
    }).catch(() => {})
  }
}
