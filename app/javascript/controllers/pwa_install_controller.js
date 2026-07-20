import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "spens-pwa-install"
const SNOOZE_DAYS = 14
const MAX_NUDGES = 3

// Suggests installing Spens as a PWA. Native prompt on Chrome/Android,
// instructions on iOS Safari. Snoozes after dismissal.
export default class extends Controller {
  static targets = ["iosSteps", "installButton"]

  connect() {
    this.deferredPrompt = null

    if (this.isStandalone() || !this.shouldNudge()) return

    if (this.isIos()) {
      if (this.isIosSafari()) this.show(true)
      return
    }

    this.beforeInstallPrompt = (event) => {
      event.preventDefault()
      this.deferredPrompt = event
      this.show(false)
    }
    window.addEventListener("beforeinstallprompt", this.beforeInstallPrompt)
  }

  disconnect() {
    if (this.beforeInstallPrompt) {
      window.removeEventListener("beforeinstallprompt", this.beforeInstallPrompt)
    }
  }

  async install() {
    if (!this.deferredPrompt) return
    this.deferredPrompt.prompt()
    const { outcome } = await this.deferredPrompt.userChoice
    this.deferredPrompt = null
    if (outcome === "accepted") {
      this.markDone()
      this.hide()
    } else {
      this.dismiss()
    }
  }

  dismiss() {
    const state = this.state()
    state.dismissedAt = Date.now()
    state.nudges = (state.nudges || 0) + 1
    this.saveState(state)
    this.hide()
  }

  show(ios) {
    this.element.hidden = false
    this.iosStepsTargets.forEach((el) => (el.hidden = !ios))
    this.installButtonTargets.forEach((el) => (el.hidden = ios))
  }

  hide() {
    this.element.hidden = true
  }

  shouldNudge() {
    const state = this.state()
    if (state.installed) return false
    if ((state.nudges || 0) >= MAX_NUDGES) return false
    if (state.dismissedAt && Date.now() - state.dismissedAt < SNOOZE_DAYS * 86_400_000) return false
    return true
  }

  markDone() {
    this.saveState({ installed: true })
  }

  state() {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEY)) || {}
    } catch {
      return {}
    }
  }

  saveState(state) {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(state))
    } catch {
      // localStorage unavailable (private mode) — just skip persistence
    }
  }

  isStandalone() {
    return window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone === true
  }

  isIos() {
    return /iphone|ipad|ipod/i.test(navigator.userAgent) ||
      (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1)
  }

  isIosSafari() {
    // Exclude in-app browsers and Chrome/Firefox on iOS, which can't add to home screen
    return this.isIos() && /safari/i.test(navigator.userAgent) && !/crios|fxios|edgios/i.test(navigator.userAgent)
  }
}
