import { afterEach, describe, expect, it, vi } from "vitest"
import PollController from "../../../app/javascript/controllers/poll_controller"
import { startStimulus } from "../helpers/stimulus"

const html = `<div data-controller="poll" data-poll-url-value="/progress" data-poll-interval-value="1000">old</div>`

describe("PollController", () => {
  afterEach(() => vi.useRealTimers())

  it("refreshes its content, then moves on once the content says it is done", async () => {
    vi.useFakeTimers({ toFake: ["setInterval", "clearInterval"] })
    const visit = vi.fn()
    window.Turbo = { visit }
    const bodies = ["<p>reading</p>", '<p>done</p><span data-poll-done-url="/review"></span>']
    global.fetch = vi.fn(async () => ({ ok: true, text: async () => bodies.shift() }))
    await startStimulus("poll", PollController, html)

    await vi.advanceTimersByTimeAsync(1000)
    expect(document.querySelector("[data-controller=poll]").innerHTML).toBe("<p>reading</p>")
    expect(visit).not.toHaveBeenCalled()

    await vi.advanceTimersByTimeAsync(1000)
    expect(visit).toHaveBeenCalledWith("/review", { action: "replace" })

    await vi.advanceTimersByTimeAsync(3000)
    expect(fetch).toHaveBeenCalledTimes(2)
  })

  it("keeps polling through a network hiccup", async () => {
    vi.useFakeTimers({ toFake: ["setInterval", "clearInterval"] })
    global.fetch = vi.fn().mockRejectedValueOnce(new Error("offline")).mockResolvedValue({ ok: true, text: async () => "<p>back</p>" })
    await startStimulus("poll", PollController, html)

    await vi.advanceTimersByTimeAsync(2000)
    expect(document.querySelector("[data-controller=poll]").innerHTML).toBe("<p>back</p>")
  })
})
