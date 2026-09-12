import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dictation"
// A mic button that hands the phrase field to the phone's own speech recognition
// (Google's on Android, Apple's on iOS) through the browser's SpeechRecognition API.
// Nothing is transcribed on our side. The button only exists where the API does:
// elsewhere the field stays exactly as it is, keyboard dictation included.
export default class extends Controller {
  static targets = ["input", "button"]
  static values = { lang: String, listeningLabel: String, idleLabel: String }

  // Android WebViews (the Spens app included) declare the API without a working engine.
  static WEBVIEW = /Turbo Native|; wv\)/

  connect() {
    const Recognition = window.SpeechRecognition || window.webkitSpeechRecognition
    if (!Recognition || !this.hasButtonTarget) return
    if (this.constructor.WEBVIEW.test(navigator.userAgent)) return

    this.Recognition = Recognition
    this.buttonTarget.hidden = false
  }

  disconnect() {
    this.#stop()
  }

  toggle() {
    this.recognition ? this.#stop() : this.#start()
  }

  #start() {
    const recognition = new this.Recognition()
    recognition.lang = this.langValue || document.documentElement.lang || "fr-FR"
    recognition.interimResults = true
    recognition.continuous = false
    recognition.maxAlternatives = 1

    this.prefix = this.inputTarget.value.trim()
    recognition.onresult = (event) => this.#write(event)
    recognition.onend = () => this.#stop()
    recognition.onerror = () => this.#stop()

    this.recognition = recognition
    this.#listening(true)
    try {
      recognition.start()
    } catch {
      this.#stop()
    }
  }

  #stop() {
    if (this.recognition) {
      const recognition = this.recognition
      this.recognition = null
      recognition.onend = recognition.onerror = recognition.onresult = null
      try { recognition.stop() } catch { /* already stopped */ }
    }
    this.#listening(false)
    if (this.hasInputTarget) this.inputTarget.focus({ preventScroll: true })
  }

  // Interim words show as they come; each one runs the same fill as a typed phrase.
  #write(event) {
    const heard = Array.from(event.results).map((r) => r[0].transcript).join(" ").trim()
    if (!heard) return

    this.inputTarget.value = this.prefix ? `${this.prefix} ${heard}` : heard
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }

  #listening(on) {
    if (!this.hasButtonTarget) return
    this.buttonTarget.classList.toggle("phrase-band__mic--listening", on)
    this.buttonTarget.setAttribute("aria-pressed", String(on))
    this.buttonTarget.setAttribute("aria-label", on ? this.listeningLabelValue : this.idleLabelValue)
  }
}
