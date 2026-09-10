import { describe, expect, it, vi } from "vitest"
import PwaInstallController from "../../../app/javascript/controllers/pwa_install_controller"
import { flushStimulus, startStimulus } from "../helpers/stimulus"

describe("PwaInstallController", () => {
  it("shows the native install action and remembers an accepted install", async () => {
    vi.stubGlobal("matchMedia", vi.fn().mockReturnValue({ matches: false }))
    await startStimulus("pwa-install", PwaInstallController, `
      <aside hidden data-controller="pwa-install">
        <p data-pwa-install-target="iosSteps"></p>
        <button data-pwa-install-target="installButton" data-action="pwa-install#install">Install</button>
      </aside>
    `)
    const prompt = vi.fn()
    const installEvent = Object.assign(new Event("beforeinstallprompt", { cancelable: true }), {
      prompt,
      userChoice: Promise.resolve({ outcome: "accepted" })
    })

    window.dispatchEvent(installEvent)
    const panel = document.querySelector("aside")
    expect(installEvent.defaultPrevented).toBe(true)
    expect(panel).not.toHaveAttribute("hidden")
    expect(document.querySelector("[data-pwa-install-target='iosSteps']").hidden).toBe(true)

    document.querySelector("button").click()
    await flushStimulus()

    expect(prompt).toHaveBeenCalledOnce()
    expect(panel.hidden).toBe(true)
    expect(JSON.parse(localStorage.getItem("spens-pwa-install"))).toEqual({ installed: true })
  })
})
