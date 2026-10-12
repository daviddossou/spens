import { afterEach, describe, expect, it, vi } from "vitest"
import DownloadController from "../../../app/javascript/controllers/download_controller"
import { flushStimulus, startStimulus } from "../helpers/stimulus"

const IPHONE_INSTAGRAM = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Instagram 300.0"
const ANDROID_CHROME = "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0 Mobile Safari/537.36"

const html = `
  <div data-controller="download" data-download-url-value="https://spens.me/fr/download" data-download-copied-value="Copied">
    <button data-download-target="tab" data-platform="android" data-action="download#choose">Android</button>
    <button data-download-target="tab" data-platform="ios" data-action="download#choose">iPhone</button>
    <button data-download-target="tab" data-platform="desktop" data-action="download#choose">Computer</button>
    <div data-download-target="done" hidden></div>
    <div data-download-target="panel" data-platform="android">
      <div data-download-target="inAppNotice" hidden></div>
      <div data-download-target="installBox" hidden><button id="install" data-action="download#install">Install</button></div>
      <p data-download-target="manualLabel" hidden></p>
    </div>
    <div data-download-target="panel" data-platform="ios" hidden>
      <div data-download-target="safariNotice" hidden>
        <button id="copy" data-action="download#copyLink"><span data-download-target="copyLabel">Copy</span></button>
      </div>
    </div>
    <div data-download-target="panel" data-platform="desktop" hidden></div>
  </div>
`

const panel = (platform) => document.querySelector(`[data-download-target="panel"][data-platform="${platform}"]`)

describe("DownloadController", () => {
  afterEach(() => vi.unstubAllGlobals())

  it("opens the iPhone tab and asks in-app browsers to switch to Safari", async () => {
    vi.stubGlobal("navigator", { ...navigator, userAgent: IPHONE_INSTAGRAM, clipboard: { writeText: vi.fn().mockResolvedValue() } })
    await startStimulus("download", DownloadController, html)

    expect(panel("ios").hidden).toBe(false)
    expect(panel("android").hidden).toBe(true)
    expect(document.querySelector("[data-download-target='safariNotice']").hidden).toBe(false)

    document.querySelector("#copy").click()
    await flushStimulus()
    expect(navigator.clipboard.writeText).toHaveBeenCalledWith("https://spens.me/fr/download")
    expect(document.querySelector("[data-download-target='copyLabel']").textContent).toBe("Copied")
  })

  it("lets the visitor switch platform by hand", async () => {
    vi.stubGlobal("navigator", { ...navigator, userAgent: ANDROID_CHROME })
    await startStimulus("download", DownloadController, html)

    document.querySelector("[data-platform='desktop']").click()

    expect(panel("desktop").hidden).toBe(false)
    expect(panel("android").hidden).toBe(true)
    expect(document.querySelector("button[data-platform='desktop']").getAttribute("aria-selected")).toBe("true")
  })

  it("offers the native install prompt and confirms an accepted install", async () => {
    vi.stubGlobal("navigator", { ...navigator, userAgent: ANDROID_CHROME })
    await startStimulus("download", DownloadController, html)
    const prompt = vi.fn()
    window.dispatchEvent(Object.assign(new Event("beforeinstallprompt", { cancelable: true }), {
      prompt,
      userChoice: Promise.resolve({ outcome: "accepted" })
    }))

    expect(document.querySelector("[data-download-target='installBox']").hidden).toBe(false)
    expect(document.querySelector("[data-download-target='inAppNotice']").hidden).toBe(true)

    document.querySelector("#install").click()
    await flushStimulus()

    expect(prompt).toHaveBeenCalledOnce()
    expect(document.querySelector("[data-download-target='done']").hidden).toBe(false)
    expect(JSON.parse(localStorage.getItem("spens-pwa-install"))).toEqual({ installed: true })
  })
})
