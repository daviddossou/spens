import { Controller } from "@hotwired/stimulus"
import { formatMoney, parseAmount } from "lib/money"

// Step 3 of onboarding: one balance per account. Under each entry the morning figure
// (entered + spent today) shows the calculation; a chip or the picker adds another place,
// which is dropped again when left blank. The button waits for every account.
export default class extends Controller {
  static targets = ["input", "morning", "extras", "chips", "template", "cta"]
  static values = {
    currency: String, locale: String, morning: String, placeholder: String, remove: String,
    pickerTitle: String, rows: Array
  }

  connect() {
    this.sync()
  }

  sync() {
    this.inputTargets.forEach((input, index) => {
      const morning = this.morningTargets[index]
      if (!morning) return
      const entered = parseAmount(input.value)
      const spent = Number(input.dataset.spent || 0)
      if (Number.isFinite(entered) && entered >= 0) {
        morning.textContent = this.morningValue.replace("%{amount}", this.fmt(entered + spent))
        morning.hidden = false
      } else {
        morning.hidden = true
      }
    })
    if (this.hasCtaTarget) {
      this.ctaTarget.disabled = this.inputTargets.some((input) => !(parseAmount(input.value) >= 0))
    }
  }

  addChip(event) {
    const chip = event.currentTarget
    this.add(chip.dataset.name)
    chip.remove()
  }

  // Everything else the user could keep money in, or a name of their own.
  pickOther() {
    const el = document.getElementById("picker-layer")
    const layer = el && this.application.getControllerForElementAndIdentifier(el, "picker-layer")
    const taken = new Set(this.extraNames())
    layer?.present({
      title: this.pickerTitleValue,
      rows: this.rowsValue.filter((row) => !taken.has(row.value)),
      selected: "",
      allowCreate: true,
      onSelect: (row, typed) => {
        const name = row ? row.value : typed
        if (name) this.add(name)
      }
    })
  }

  add(name) {
    if (this.extraNames().includes(name)) return
    const index = this.extrasTarget.children.length
    const card = this.templateTarget.content.firstElementChild.cloneNode(true)
    const [icon, label] = this.split(name)
    card.querySelector('[data-slot="icon"]').textContent = icon
    card.querySelector('[data-slot="name"]').textContent = label
    card.querySelector('[data-slot="remove"], .balance-card__remove').textContent = this.removeValue
    const hidden = card.querySelector('[data-slot="hidden"]')
    hidden.name = `balances[extra][${index}][name]`
    hidden.value = name
    const amount = card.querySelector('[data-slot="amount"]')
    amount.name = `balances[extra][${index}][amount]`
    amount.placeholder = this.placeholderValue
    amount.setAttribute("aria-label", label)
    this.extrasTarget.appendChild(card)
    amount.focus()
  }

  remove(event) {
    const card = event.currentTarget.closest(".balance-card")
    const name = card.querySelector('[data-slot="hidden"]').value
    card.remove()
    // The chip comes back so the place can be picked again.
    if (this.hasChipsTarget && this.rowsValue.some((row) => row.value === name)) {
      const chip = document.createElement("button")
      chip.type = "button"
      chip.className = "name-chip"
      chip.dataset.name = name
      chip.dataset.action = "onboarding--balances#addChip"
      chip.textContent = `+ ${name}`
      this.chipsTarget.appendChild(chip)
    }
  }

  extraNames() {
    return Array.from(this.extrasTarget.querySelectorAll('[data-slot="hidden"]')).map((el) => el.value)
  }

  split(name) {
    const match = name.match(/^([^\p{L}\p{N}]+)\s*(.*)$/u)
    return match && match[2] ? [match[1].trim(), match[2]] : ["", name]
  }

  fmt(value) {
    return formatMoney(value, this.currencyValue, this.hasLocaleValue ? this.localeValue : undefined)
  }
}
