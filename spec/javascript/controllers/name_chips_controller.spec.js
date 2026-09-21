import { describe, expect, it, vi } from "vitest"
import NameChipsController from "../../../app/javascript/controllers/name_chips_controller"
import PickerController from "../../../app/javascript/controllers/picker_controller"
import { startStimulus, flushStimulus } from "../helpers/stimulus"

describe("NameChipsController", () => {
  it("filters suggestions and fills the input from a chip", async () => {
    await startStimulus("name-chips", NameChipsController, `
      <div data-controller="name-chips"
           data-name-chips-suggestions-value='["Alice","Alain","Bob"]'
           data-name-chips-limit-value="3">
        <input value="Al" data-name-chips-target="input" data-action="input->name-chips#render">
        <div data-name-chips-target="chips"></div>
      </div>
    `)
    const input = document.querySelector("input")
    const change = vi.fn()
    input.addEventListener("change", change)

    expect([...document.querySelectorAll(".name-chip")].map(chip => chip.textContent)).toEqual(["Alice", "Alain"])
    document.querySelector(".name-chip").click()

    expect(input.value).toBe("Alice")
    expect(change).toHaveBeenCalledOnce()
    expect([...document.querySelectorAll(".name-chip")].map(chip => chip.textContent)).toEqual([])
  })

  it("adds a see-all chip when suggestions exceed the visible limit", async () => {
    await startStimulus("name-chips", NameChipsController, `
      <div data-controller="name-chips"
           data-name-chips-suggestions-value='["Alice","Bob","Chloé"]'
           data-name-chips-limit-value="2"
           data-name-chips-see-all-label-value="See all">
        <input data-name-chips-target="input">
        <div data-name-chips-target="chips"></div>
      </div>
    `)

    expect(document.querySelectorAll(".name-chip")).toHaveLength(3)
    expect(document.querySelector(".name-chip--all")).toHaveTextContent("See all")
  })

  it("fills a picker field from a chip and refreshes its visible label", async () => {
    const rows = JSON.stringify([{ value: "📲 Mobile Money", label: "Mobile Money", icon: "📲" }])
    const application = await startStimulus("picker", PickerController, `
      <div data-controller="name-chips" data-name-chips-suggestions-value='["📲 Mobile Money"]'>
        <div data-controller="picker" data-picker-rows-value='${rows}' data-picker-placeholder-value="Choose">
          <input type="hidden" name="account[account_name]" data-picker-target="input" data-name-chips-target="input">
          <span data-picker-target="label">Choose</span>
        </div>
        <div data-name-chips-target="chips"></div>
      </div>
    `)
    application.register("name-chips", NameChipsController)
    await flushStimulus()

    document.querySelector(".name-chip").click()

    expect(document.querySelector("input").value).toBe("📲 Mobile Money")
    expect(document.querySelector("[data-picker-target='label']").textContent).toContain("Mobile Money")
  })
})
