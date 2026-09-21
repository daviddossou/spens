import { afterEach, describe, expect, it, vi } from "vitest"
import PushController from "../../../app/javascript/controllers/push_controller"
import { startStimulus } from "../helpers/stimulus"

const html = (key = "BElmbw") => `
  <div data-controller="push" data-push-key-value="${key}" data-push-url-value="/push_subscription">
    <p data-push-target="status" data-state="on" hidden>on</p>
    <p data-push-target="status" data-state="blocked" hidden>blocked</p>
    <p data-push-target="status" data-state="email" hidden>email</p>
    <button data-push-target="status" data-state="off" data-action="push#subscribe" hidden>turn on</button>
  </div>`

const shown = () => [...document.querySelectorAll("[data-push-target]")].filter((el) => !el.hidden).map((el) => el.dataset.state)

describe("PushController", () => {
  afterEach(() => {
    delete window.PushManager
    delete window.Notification
    delete navigator.serviceWorker
    vi.restoreAllMocks()
  })

  it("says the reminder comes by e-mail where push does not exist", async () => {
    await startStimulus("push", PushController, html())

    expect(shown()).toEqual(["email"])
    await document.querySelector("button").click()
    expect(shown()).toEqual(["email"])
  })

  it("subscribes the browser and posts the subscription once allowed", async () => {
    const subscription = { toJSON: () => ({ endpoint: "https://push.example.com/abc", keys: { p256dh: "k", auth: "a" } }) }
    const pushManager = { getSubscription: vi.fn().mockResolvedValue(null), subscribe: vi.fn().mockResolvedValue(subscription) }
    window.PushManager = function () {}
    window.Notification = { permission: "default", requestPermission: vi.fn(async () => (window.Notification.permission = "granted")) }
    Object.defineProperty(navigator, "serviceWorker", { value: { ready: Promise.resolve({ pushManager }) }, configurable: true })
    const fetchMock = vi.spyOn(globalThis, "fetch").mockResolvedValue({ ok: true })

    const application = await startStimulus("push", PushController, html())
    expect(shown()).toEqual(["off"])

    const controller = application.getControllerForElementAndIdentifier(document.querySelector("[data-controller='push']"), "push")
    await controller.subscribe()

    expect(pushManager.subscribe).toHaveBeenCalledWith(expect.objectContaining({ userVisibleOnly: true }))
    expect(fetchMock).toHaveBeenCalledWith("/push_subscription", expect.objectContaining({ method: "POST" }))
    expect(JSON.parse(fetchMock.mock.calls[0][1].body).subscription.endpoint).toBe("https://push.example.com/abc")
    expect(shown()).toEqual(["on"])
  })

  it("posts nothing when the user refuses", async () => {
    window.PushManager = function () {}
    window.Notification = { permission: "default", requestPermission: vi.fn(async () => (window.Notification.permission = "denied")) }
    Object.defineProperty(navigator, "serviceWorker", { value: { ready: Promise.resolve({}) }, configurable: true })
    const fetchMock = vi.spyOn(globalThis, "fetch")

    const application = await startStimulus("push", PushController, html())
    await application.getControllerForElementAndIdentifier(document.querySelector("[data-controller='push']"), "push").subscribe()

    expect(fetchMock).not.toHaveBeenCalled()
    expect(shown()).toEqual(["blocked"])
  })
})
