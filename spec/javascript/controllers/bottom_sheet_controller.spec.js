import { describe, expect, it, vi } from "vitest"
import BottomSheetController from "../../../app/javascript/controllers/bottom_sheet_controller"
import { startStimulus } from "../helpers/stimulus"

const markup = `
  <aside data-controller="bottom-sheet">
    <div data-bottom-sheet-target="backdrop"></div>
    <div data-bottom-sheet-target="panel"></div>
    <turbo-frame data-bottom-sheet-target="frame"
                 data-action="turbo:frame-load->bottom-sheet#frameLoaded"><form></form></turbo-frame>
  </aside>
`

describe("BottomSheetController", () => {
  it("opens for loaded frame content and closes on Escape", async () => {
    await startStimulus("bottom-sheet", BottomSheetController, markup)
    const sheet = document.querySelector("aside")
    const frame = document.querySelector("turbo-frame")

    frame.dispatchEvent(new Event("turbo:frame-load", { bubbles: true }))
    expect(sheet).toHaveAttribute("data-state", "open")
    expect(document.body).toHaveClass("bottom-sheet-open")

    document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", cancelable: true }))
    expect(sheet).not.toHaveAttribute("data-state")
    expect(document.body).not.toHaveClass("bottom-sheet-open")
  })

  it("clears frame content after the close animation", async () => {
    const application = await startStimulus("bottom-sheet", BottomSheetController, markup)
    const sheet = document.querySelector("aside")
    const frame = document.querySelector("turbo-frame")
    const controller = application.getControllerForElementAndIdentifier(sheet, "bottom-sheet")
    frame.setAttribute("src", "/transactions/new")
    controller.open()
    vi.useFakeTimers()

    controller.close()
    vi.advanceTimersByTime(350)

    expect(frame).not.toHaveAttribute("src")
    expect(frame).toBeEmptyDOMElement()
  })
})
