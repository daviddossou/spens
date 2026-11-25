import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="auto-submit"
// Submits its form as soon as a file is picked (the "+ Ajouter" tile of an import).
export default class extends Controller {
  submit(event) {
    if (event.target.files && !event.target.files.length) return

    this.element.classList.add("is-sending")
    this.element.requestSubmit()
  }
}
