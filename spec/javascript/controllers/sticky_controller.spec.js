import { describe, expect, it, vi } from "vitest"
import StickyController from "../../../app/javascript/controllers/sticky_controller"
import { flushStimulus, startStimulus } from "../helpers/stimulus"

describe("StickyController", () => {
  it("toggles its stuck class from intersection state and disconnects its observer", async () => {
    const observe = vi.fn()
    const disconnect = vi.fn()
    let callback
    let options
    vi.stubGlobal("IntersectionObserver", class {
      constructor(handler, observerOptions) {
        callback = handler
        options = observerOptions
      }
      observe = observe
      disconnect = disconnect
    })

    await startStimulus("sticky", StickyController, `
      <div style="position: sticky; top: 10px"
           data-controller="sticky"
           data-sticky-stuck-class="is-stuck"></div>
    `)
    const element = document.querySelector("[data-controller='sticky']")

    expect(observe).toHaveBeenCalledWith(element)
    expect(options).toEqual({ threshold: [1], rootMargin: "-11px 0px 0px 0px" })
    callback([{ intersectionRatio: 0.5 }])
    expect(element).toHaveClass("is-stuck")
    callback([{ intersectionRatio: 1 }])
    expect(element).not.toHaveClass("is-stuck")

    element.remove()
    await flushStimulus()
    expect(disconnect).toHaveBeenCalledOnce()
  })
})
