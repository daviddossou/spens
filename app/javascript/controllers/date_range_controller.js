import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["picker", "customBtn"]

  showPicker(event) {
    // If picker is already visible and Custom is active, let the link navigate
    if (this.pickerTarget.classList.contains("analytics-period__custom--visible")) {
      return
    }

    // Prevent default navigation — just reveal the picker
    event.preventDefault()
    this.pickerTarget.classList.add("analytics-period__custom--visible")
  }

  submit() {
    // Auto-submit the form when a date input changes
    this.pickerTarget.querySelector("form").requestSubmit()
  }
}
