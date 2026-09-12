import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="phrase-fill"
// The phrase field above the transaction form. Every pause in typing reloads the
// "transaction_form" frame with the phrase, so the server's parser fills the fields
// below. Anything the user set by hand is locked and travels with each reload, so
// the parser never rewrites it — and so a kind switch keeps both the phrase and the
// manual choices.
export default class extends Controller {
  static targets = ["input", "help", "status", "title", "subtitle"]
  static values = { url: String, pending: String }

  connect() {
    this.locked = {}
    this.frame = document.getElementById("transaction_form")
    if (!this.frame) return

    this.onBeforeFetch = (event) => this.#carry(event)
    this.onFrameLoad = () => this.#sync()
    this.onFieldChange = (event) => this.#lockFromEvent(event)
    this.onFieldInput = (event) => this.#lockFromEvent(event)
    this.onFrameClick = (event) => this.#lockFromClick(event)
    this.onFrameMissing = (event) => this.#followRedirect(event)

    this.frame.addEventListener("turbo:before-fetch-request", this.onBeforeFetch)
    this.frame.addEventListener("turbo:frame-load", this.onFrameLoad)
    this.frame.addEventListener("turbo:frame-missing", this.onFrameMissing)
    this.frame.addEventListener("change", this.onFieldChange)
    this.frame.addEventListener("input", this.onFieldInput)
    this.frame.addEventListener("click", this.onFrameClick, true)
    this.#sync()
  }

  disconnect() {
    clearTimeout(this.timer)
    clearTimeout(this.aiTimer)
    if (!this.frame) return
    this.frame.removeEventListener("turbo:before-fetch-request", this.onBeforeFetch)
    this.frame.removeEventListener("turbo:frame-load", this.onFrameLoad)
    this.frame.removeEventListener("turbo:frame-missing", this.onFrameMissing)
    this.frame.removeEventListener("change", this.onFieldChange)
    this.frame.removeEventListener("input", this.onFieldInput)
    this.frame.removeEventListener("click", this.onFrameClick, true)
  }

  // Debounced: the rules pass reloads the frame once the user pauses, never on every keystroke.
  type() {
    clearTimeout(this.timer)
    clearTimeout(this.aiTimer)
    const text = this.inputTarget.value.trim()
    // An emptied phrase is a fresh start: the choices made for the previous one don't carry over.
    if (!text) this.locked = {}
    this.#compact(text.length > 0)
    this.timer = setTimeout(() => this.refill(), 350)
  }

  // Enter = "I'm done": straight to the AI pass.
  submitOnEnter(event) {
    if (event.key !== "Enter") return
    event.preventDefault()
    clearTimeout(this.timer)
    clearTimeout(this.aiTimer)
    this.refill({ ai: true })
  }

  refill({ ai = false } = {}) {
    if (!this.frame) return
    if (this.hasStatusTarget && this.hasPendingValue) {
      this.statusTarget.hidden = false
      this.statusTarget.classList.remove("phrase-band__status--ok")
      this.statusTarget.textContent = this.pendingValue
    }
    this.refilling = true
    this.withAi = ai
    const url = new URL(this.urlValue, window.location.origin)
    if (ai) url.searchParams.set("ai", "1")
    // A changed src is what makes the frame fetch; the AI flag alone is enough of a change.
    this.frame.src = `${url.pathname}${url.search}`
  }

  // The rules left gaps and the phrase hasn't moved: one AI pass, like quick add did.
  #scheduleAi(form) {
    clearTimeout(this.aiTimer)
    if (form.dataset.phraseNeedsAi !== "true") return
    if (!this.hasInputTarget || this.inputTarget.value.trim() !== form.dataset.phraseText) return
    this.aiTimer = setTimeout(() => this.refill({ ai: true }), 1200)
  }

  // Every frame request — ours or a kind-switch click — carries the phrase and the locks.
  // Only requests the frame itself makes count: a hover prefetch of a kind card, or a form
  // submission, also bubble through here and must never read as a manual choice.
  #carry(event) {
    if (event.target !== this.frame) return
    const url = event.detail.url
    if (!(url instanceof URL)) return

    const text = this.hasInputTarget ? this.inputTarget.value.trim() : ""
    if (text) url.searchParams.set("text", text)
    else url.searchParams.delete("text")

    // A kind card the user tapped is a manual choice: lock it before the request goes out.
    if (!this.refilling && url.searchParams.has("kind")) this.locked.kind = url.searchParams.get("kind")
    if (!this.refilling) url.searchParams.delete("ai")
    this.refilling = false

    Object.entries(this.locked).forEach(([field, value]) => {
      if (value) url.searchParams.set(`locked[${field}]`, value)
    })
  }

  #lockFromEvent(event) {
    const field = this.#fieldName(event.target)
    if (!field) return
    // The amount locks as it's typed; the other fields on a committed change.
    if (event.type === "input" && field !== "amount") return
    this.locked[field] = event.target.value.trim()
  }

  // Debt cards and date pills write hidden inputs without a change event.
  #lockFromClick(event) {
    const card = event.target.closest(".debt-card")
    const pill = event.target.closest("[data-date-mode]")
    if (!card && !pill) return

    setTimeout(() => {
      if (card) {
        this.locked.kind = this.#value("kind")
        this.locked.direction = this.#value("direction")
      }
      if (pill) this.locked.transaction_date = this.#value("transaction_date")
    }, 0)
  }

  #fieldName(el) {
    const match = el?.name?.match(/^transaction\[(\w+)\]$/)
    return match ? match[1] : null
  }

  #value(field) {
    return this.frame.querySelector(`[name="transaction[${field}]"]`)?.value?.trim() || ""
  }

  // The reloaded form carries its own heading and a one-line summary of what the phrase filled.
  #sync() {
    const form = this.frame?.querySelector("form[data-phrase-title]")
    if (!form) return

    if (this.hasTitleTarget) this.titleTarget.textContent = form.dataset.phraseTitle
    if (this.hasSubtitleTarget) this.subtitleTarget.textContent = form.dataset.phraseSubtitle
    if (this.hasStatusTarget) {
      const summary = form.dataset.phraseSummary || ""
      this.statusTarget.textContent = summary
      this.statusTarget.hidden = summary.length === 0
      this.statusTarget.classList.toggle("phrase-band__status--ok", (form.dataset.phraseFilledCount || "0") !== "0")
    }
    this.#scheduleAi(form)
  }

  // A saved transaction redirects to its page, which has no form frame. Inside the sheet the
  // bottom-sheet controller closes and follows; on a full page nobody would, so do it here.
  #followRedirect(event) {
    if (this.frame.closest('.bottom-sheet[data-state="open"]')) return

    event.preventDefault()
    window.Turbo.visit(event.detail.response.url, { action: "replace" })
  }

  // Once a phrase is there the help line goes; the band stays one input tall.
  #compact(on) {
    if (this.hasHelpTarget) this.helpTarget.hidden = on
  }
}
