import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="kind-switch"
// Carries the live field values across a kind switch (the category is dropped),
// then drives the transaction_form frame to the clicked card's URL.
export default class extends Controller {
  static CARRIED = [
    "amount",
    "account_name",
    "from_account_name",
    "to_account_name",
    "note",
    "description",
    "contact_name",
    "direction"
  ]

  switch(event) {
    event.preventDefault()

    const url = new URL(event.currentTarget.href, window.location.origin)

    this.constructor.CARRIED.forEach((field) => {
      const value = this.fieldValue(field)
      if (value) {
        url.searchParams.set(field, value)
      } else {
        url.searchParams.delete(field)
      }
    })

    const target = `${url.pathname}${url.search}`
    const frame = document.getElementById("transaction_form")

    if (frame) {
      frame.src = target
    } else {
      window.Turbo.visit(target, { action: "replace" })
    }
  }

  fieldValue(field) {
    const input = this.element.querySelector(`[name="transaction[${field}]"]`)
    return input ? input.value.trim() : ""
  }
}
