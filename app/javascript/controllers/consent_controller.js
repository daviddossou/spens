import { Controller } from "@hotwired/stimulus"

// Marketing-consent banner. The decision lives in the mkt_consent cookie, read
// server-side to gate the Meta pixel and every CAPI send. Accepting reloads so
// the pixel boots on this very page view.
export default class extends Controller {
  accept() {
    this.#store("granted")
    window.location.reload()
  }

  decline() {
    this.#store("denied")
    this.element.remove()
  }

  #store(value) {
    const expires = new Date(Date.now() + 365 * 24 * 3600 * 1000).toUTCString()
    document.cookie = `mkt_consent=${value}; path=/; expires=${expires}; SameSite=Lax`
  }
}
