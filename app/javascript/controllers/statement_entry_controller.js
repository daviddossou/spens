import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="statement-entry"
// The photo button of the phrase band: opens the import action sheet, and sends the
// chosen captures as soon as the picker closes. Only the input that was used is posted.
export default class extends Controller {
  static targets = ["button", "dialog", "form", "status", "origin"]

  open() {
    this.dialogTarget.showModal()
    this.buttonTarget.classList.add("is-active")
  }

  close() {
    this.dialogTarget.close()
  }

  closed() {
    this.buttonTarget.classList.remove("is-active")
  }

  // A tap on the dimmed backdrop lands on the <dialog> itself.
  backdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  submit(event) {
    if (!event.target.files.length) return

    this.formTarget.querySelectorAll("input[type=file]").forEach((input) => {
      if (input !== event.target) input.disabled = true
    })
    this.originTarget.value = event.target.dataset.origin || ""
    this.dialogTarget.classList.add("is-sending")
    this.statusTarget.hidden = false
    this.formTarget.requestSubmit()
  }
}
