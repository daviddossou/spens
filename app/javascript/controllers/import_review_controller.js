import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="import-review"
// The review list of a statement import. A category chip opens the shared category
// picker of its side in one tap; the choice is saved on the line and the list re-renders.
export default class extends Controller {
  static targets = ["picker"]

  pickCategory(event) {
    const chip = event.currentTarget
    const picker = this.pickerTargets.find((el) => el.dataset.kind === chip.dataset.kind)
    const controller = picker && this.application.getControllerForElementAndIdentifier(picker, "picker")
    if (!controller) return

    this.lineUrl = chip.dataset.url
    controller.inputTarget.value = chip.dataset.value || ""
    controller.render()
    controller.open()
  }

  async picked(event) {
    const value = event.target.value
    if (!this.lineUrl || !value) return

    const body = new FormData()
    body.append("line[transaction_type_name]", value)
    const response = await fetch(this.lineUrl, {
      method: "PATCH",
      body,
      credentials: "same-origin",
      headers: { Accept: "text/vnd.turbo-stream.html", "X-CSRF-Token": this.csrfToken }
    })
    this.lineUrl = null
    if (response.ok) window.Turbo.renderStreamMessage(await response.text())
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content || ""
  }
}
