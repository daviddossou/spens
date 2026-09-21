import { Controller } from "@hotwired/stimulus"

// Subscribes this browser to Web Push when the user accepts a reminder. Always best
// effort: where push is missing (the Android app's WebView, an iPhone tab) or refused,
// nothing breaks and the reminder arrives by e-mail instead.
export default class extends Controller {
  static values = { key: String, url: String }
  static targets = ["status"]

  connect() {
    if (this.hasStatusTarget) this.showStatus()
  }

  get supported() {
    return this.keyValue && "serviceWorker" in navigator && "PushManager" in window && "Notification" in window
  }

  // Bound to the accepting click: browsers only ask for permission from a user gesture.
  async subscribe() {
    if (!this.supported) return

    try {
      if ((await Notification.requestPermission()) !== "granted") return this.showStatus()

      const registration = await navigator.serviceWorker.ready
      const subscription = await registration.pushManager.getSubscription() ||
        await registration.pushManager.subscribe({ userVisibleOnly: true, applicationServerKey: this.decodedKey() })

      await fetch(this.urlValue, {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": this.csrfToken() },
        credentials: "same-origin",
        body: JSON.stringify({ subscription: subscription.toJSON() })
      })
    } catch (error) {
      console.warn("Push subscription failed", error)
    }
    this.showStatus()
  }

  // Says where this device stands: "on", "blocked" or "email" (no push here).
  showStatus() {
    if (!this.hasStatusTarget) return
    const state = !this.supported ? "email" : Notification.permission === "granted" ? "on"
      : Notification.permission === "denied" ? "blocked" : "off"
    this.statusTargets.forEach((el) => { el.hidden = el.dataset.state !== state })
  }

  decodedKey() {
    const padded = this.keyValue.padEnd(this.keyValue.length + ((4 - (this.keyValue.length % 4)) % 4), "=")
    const raw = atob(padded.replace(/-/g, "+").replace(/_/g, "/"))
    return Uint8Array.from(raw, (char) => char.charCodeAt(0))
  }

  csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }
}
