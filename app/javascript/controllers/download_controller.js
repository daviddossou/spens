import { Controller } from "@hotwired/stimulus"
import { detectPlatform } from "lib/platform"

const BANNER_STORAGE_KEY = "spens-pwa-install"

// /download: opens the visitor's platform tab. Plan A is the browser's own
// install prompt; plan B, the manual steps, opens when it isn't available.
export default class extends Controller {
  static targets = ["tab", "panel", "installBox", "manual", "inAppNotice", "safariNotice", "done", "copyLabel"]
  static values = { url: String, copied: String }

  connect() {
    this.platform = detectPlatform()
    this.select(this.platform.os)

    if (this.platform.inApp) {
      this.inAppNoticeTargets.forEach((el) => (el.hidden = false))
      this.installBoxTargets.forEach((el) => (el.hidden = true))
      this.openManual()
    }
    if (this.platform.os === "ios" && !this.platform.safari) this.safariNoticeTargets.forEach((el) => (el.hidden = false))

    this.beforeInstallPrompt = (event) => {
      event.preventDefault()
      this.deferredPrompt = event
      this.installBoxTargets.forEach((el) => (el.hidden = false))
    }
    this.appInstalled = () => this.showDone()
    window.addEventListener("beforeinstallprompt", this.beforeInstallPrompt)
    window.addEventListener("appinstalled", this.appInstalled)

    window.posthog?.capture("download_page_viewed", {
      os: this.platform.os, in_app: this.platform.inApp, safari: this.platform.safari
    })
  }

  disconnect() {
    window.removeEventListener("beforeinstallprompt", this.beforeInstallPrompt)
    window.removeEventListener("appinstalled", this.appInstalled)
  }

  choose(event) {
    this.select(event.currentTarget.dataset.platform)
    window.posthog?.capture("download_platform_chosen", { platform: event.currentTarget.dataset.platform, os: this.platform.os })
  }

  select(platform) {
    this.tabTargets.forEach((tab) => {
      const active = tab.dataset.platform === platform
      tab.setAttribute("aria-selected", active)
      tab.tabIndex = active ? 0 : -1
    })
    this.panelTargets.forEach((panel) => (panel.hidden = panel.dataset.platform !== platform))
  }

  async install() {
    if (!this.deferredPrompt) {
      window.posthog?.capture("download_install_fallback", { os: this.platform.os })
      this.openManual()
      this.manualTargets[0]?.scrollIntoView({ behavior: "smooth", block: "start" })
      return
    }
    this.deferredPrompt.prompt()
    const { outcome } = await this.deferredPrompt.userChoice
    this.deferredPrompt = null
    window.posthog?.capture("pwa_install_prompted", { outcome, source: "download_page" })
    if (outcome === "accepted") this.showDone()
  }

  async copyLink() {
    window.posthog?.capture("download_link_copied", { os: this.platform.os, in_app: this.platform.inApp })
    try {
      await navigator.clipboard.writeText(this.urlValue)
    } catch {
      window.prompt("", this.urlValue)
      return
    }
    this.copyLabelTargets.forEach((label) => {
      label.dataset.original ||= label.textContent
      label.textContent = this.copiedValue
      setTimeout(() => (label.textContent = label.dataset.original), 2500)
    })
  }

  openManual() {
    this.manualTargets.forEach((details) => (details.open = true))
  }

  openInBrowser() {
    window.posthog?.capture("download_open_in_browser_clicked", { os: this.platform.os })
  }

  showDone() {
    this.doneTarget.hidden = false
    this.installBoxTargets.forEach((el) => (el.hidden = true))
    try {
      localStorage.setItem(BANNER_STORAGE_KEY, JSON.stringify({ installed: true }))
    } catch {
      // localStorage unavailable (private mode)
    }
  }
}
