import { describe, expect, it, vi } from "vitest"
import DateRangeController from "../../../app/javascript/controllers/date_range_controller"
import { startStimulus } from "../helpers/stimulus"

const markup = `
  <section data-controller="date-range">
    <a href="/analytics?period=custom" data-action="date-range#showPicker">Custom</a>
    <div data-date-range-target="picker">
      <form><input type="date" data-action="change->date-range#submit"></form>
    </div>
  </section>
`

describe("DateRangeController", () => {
  it("reveals the custom picker and prevents the first navigation", async () => {
    await startStimulus("date-range", DateRangeController, markup)
    const event = new MouseEvent("click", { bubbles: true, cancelable: true })

    document.querySelector("a").dispatchEvent(event)

    expect(event.defaultPrevented).toBe(true)
    expect(document.querySelector("[data-date-range-target='picker']"))
      .toHaveClass("analytics-period__custom--visible")
  })

  it("submits when a date changes", async () => {
    await startStimulus("date-range", DateRangeController, markup)
    const form = document.querySelector("form")
    form.requestSubmit = vi.fn()

    document.querySelector("input").dispatchEvent(new Event("change", { bubbles: true }))

    expect(form.requestSubmit).toHaveBeenCalledOnce()
  })
})
