import { Controller } from "@hotwired/stimulus"

// Renders a Turnstile widget explicitly so it survives Turbo navigations and
// form re-renders. The token lands in the hidden cf-turnstile-response input
// that Turnstile adds inside the element.
const API_URL = "https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit"
let apiLoading

function loadApi() {
  if (window.turnstile) return Promise.resolve()
  apiLoading ||= new Promise((resolve, reject) => {
    const script = document.createElement("script")
    script.src = API_URL
    script.async = true
    script.onload = resolve
    script.onerror = () => { apiLoading = null; reject(new Error("turnstile api failed to load")) }
    document.head.appendChild(script)
  })
  return apiLoading
}

export default class extends Controller {
  static values = { sitekey: String }

  async connect() {
    try {
      await loadApi()
    } catch {
      return // no widget: the server rejects the submit with a retry message
    }
    if (!this.element.isConnected) return

    this.element.replaceChildren() // drop a stale iframe restored from the Turbo cache
    this.widgetId = window.turnstile.render(this.element, {
      sitekey: this.sitekeyValue,
      appearance: "interaction-only",
      language: document.documentElement.lang || "auto",
      "expired-callback": () => window.turnstile.reset(this.widgetId)
    })
  }

  disconnect() {
    if (this.widgetId === undefined) return
    window.turnstile.remove(this.widgetId)
    this.widgetId = undefined
  }
}
