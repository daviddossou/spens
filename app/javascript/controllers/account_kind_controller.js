import { Controller } from "@hotwired/stimulus"

// "Spending or savings?" is never asked: the account's name decides (a savings
// template counts as put aside), and "Change" flips it. A manual choice sticks.
export default class extends Controller {
  static targets = ["input", "text"]
  static values = { names: Array, manual: Boolean, everyday: String, setAside: String }

  infer(event) {
    if (this.manualValue || !event.target.name?.includes("[account_name]")) return
    this.set(this.namesValue.includes(this.fold(event.target.value)))
  }

  toggle() {
    this.manualValue = true
    this.set(this.inputTarget.value !== "true")
  }

  set(setAside) {
    this.inputTarget.value = setAside
    this.textTarget.innerHTML = setAside ? this.setAsideValue : this.everydayValue
  }

  // Mirrors Account.fold_name: no leading emoji, accents or case.
  fold(name) {
    return name.replace(/^[^\p{L}\p{N}]+/u, "").trim().normalize("NFD").replace(/\p{Mn}/gu, "").toLowerCase()
  }
}
