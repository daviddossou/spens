import { describe, expect, it } from "vitest"
import LazySelectController from "../../../app/javascript/controllers/lazy_select_controller"
import { startStimulus } from "../helpers/stimulus"

describe("LazySelectController", () => {
  it("upgrades its select only after the details element opens", async () => {
    await startStimulus("lazy-select", LazySelectController, `
      <details data-controller="lazy-select"><select></select></details>
    `)
    const details = document.querySelector("details")
    const select = document.querySelector("select")

    details.dispatchEvent(new Event("toggle"))
    expect(select).not.toHaveAttribute("data-controller")

    details.open = true
    details.dispatchEvent(new Event("toggle"))
    expect(select).toHaveAttribute("data-controller", "searchable-select")
  })
})
