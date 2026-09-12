import { describe, expect, it, vi } from "vitest"
import InfiniteScrollController from "../../../app/javascript/controllers/infinite_scroll_controller"
import { flushStimulus, startStimulus } from "../helpers/stimulus"

describe("InfiniteScrollController", () => {
  it("loads the next Turbo Stream page when its trigger intersects", async () => {
    const observe = vi.fn()
    let intersectionCallback
    vi.stubGlobal("IntersectionObserver", class {
      constructor(callback) { intersectionCallback = callback }
      observe = observe
      unobserve = vi.fn()
      disconnect = vi.fn()
    })
    const fetch = vi.fn().mockResolvedValue({ ok: true, text: () => Promise.resolve("<turbo-stream></turbo-stream>") })
    const renderStreamMessage = vi.fn()
    vi.stubGlobal("fetch", fetch)
    vi.stubGlobal("Turbo", { renderStreamMessage })

    await startStimulus("infinite-scroll", InfiniteScrollController, `
      <div data-controller="infinite-scroll"
           data-infinite-scroll-url-value="/transactions"
           data-infinite-scroll-page-value="2">
        <div data-infinite-scroll-target="trigger"></div>
        <span class="hidden" data-infinite-scroll-target="spinner"></span>
      </div>
    `)
    const trigger = document.querySelector("[data-infinite-scroll-target='trigger']")

    expect(observe).toHaveBeenCalledWith(trigger)
    intersectionCallback([{ isIntersecting: true }])
    await flushStimulus()
    await flushStimulus()

    expect(fetch).toHaveBeenCalledWith(new URL("/transactions?page=2", window.location.origin), {
      headers: { Accept: "text/vnd.turbo-stream.html" }
    })
    expect(renderStreamMessage).toHaveBeenCalledWith("<turbo-stream></turbo-stream>")
    expect(document.querySelector("[data-infinite-scroll-target='spinner']")).toHaveClass("hidden")
  })
})
