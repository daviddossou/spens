import { Controller } from "@hotwired/stimulus"

// Lets the guide PDF download start, then carries the visitor to the thank-you page.
export default class extends Controller {
  static values = { url: String, delay: { type: Number, default: 1200 } }

  redirect() {
    setTimeout(() => window.location.assign(this.urlValue), this.delayValue)
  }
}
