import { describe, expect, it } from "vitest"
import TaxGroupController from "../../../app/javascript/controllers/tax_group_controller"
import { startStimulus } from "../helpers/stimulus"

describe("TaxGroupController", () => {
  it("toggles the group open state", async () => {
    await startStimulus("tax-group", TaxGroupController, `
      <div data-controller="tax-group">
        <button data-action="tax-group#toggle">Toggle</button>
      </div>
    `)
    const group = document.querySelector("[data-controller='tax-group']")
    const button = document.querySelector("button")

    button.click()
    expect(group).toHaveClass("admin-taxgroup--open")

    button.click()
    expect(group).not.toHaveClass("admin-taxgroup--open")
  })
})
