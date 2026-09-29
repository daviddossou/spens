import { Controller } from "@hotwired/stimulus"
import { suggestEmail } from "lib/email_typo"

// "Did you mean name@gmail.com?" under an e-mail field, shown on blur, accepted with one tap.
// Connects to data-controller="email-suggest" (on the form); the message value holds %{email}.
export default class extends Controller {
  static targets = ["input", "hint", "before", "suggestion", "after"]
  static values = { message: String }

  check() {
    const suggestion = suggestEmail(this.inputTarget.value)
    if (!suggestion) return this.hide()

    const [before, after] = this.messageValue.split("%{email}")
    this.beforeTarget.textContent = before
    this.suggestionTarget.textContent = suggestion
    this.afterTarget.textContent = after || ""
    this.hintTarget.hidden = false
  }

  accept() {
    this.inputTarget.value = this.suggestionTarget.textContent
    this.hide()
    this.inputTarget.focus()
  }

  hide() {
    this.hintTarget.hidden = true
  }
}
