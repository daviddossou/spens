import { describe, expect, it, vi } from "vitest"
import KindSwitchController from "../../../app/javascript/controllers/kind_switch_controller"
import { startStimulus } from "../helpers/stimulus"

const fields = `
  <input name="transaction[amount]" value=" 42 ">
  <input name="transaction[note]" value="Lunch">
  <input name="transaction[contact_name]" value=" ">
`

describe("KindSwitchController", () => {
  it("carries form values into the transaction Turbo Frame", async () => {
    await startStimulus("kind-switch", KindSwitchController, `
      <div data-controller="kind-switch">
        ${fields}
        <a href="/transactions/new?kind=income&amp;contact_name=old" data-action="kind-switch#switch">Income</a>
      </div>
      <turbo-frame id="transaction_form"></turbo-frame>
    `)

    document.querySelector("a").click()

    const url = new URL(document.getElementById("transaction_form").src, window.location.origin)
    expect(url.pathname).toBe("/transactions/new")
    expect(url.searchParams.get("kind")).toBe("income")
    expect(url.searchParams.get("amount")).toBe("42")
    expect(url.searchParams.get("note")).toBe("Lunch")
    expect(url.searchParams.has("contact_name")).toBe(false)
  })

  it("uses a replacement Turbo visit when the frame is absent", async () => {
    const visit = vi.fn()
    vi.stubGlobal("Turbo", { visit })
    await startStimulus("kind-switch", KindSwitchController, `
      <div data-controller="kind-switch">${fields}<a href="/transactions/new?kind=expense" data-action="kind-switch#switch">Expense</a></div>
    `)

    document.querySelector("a").click()

    expect(visit).toHaveBeenCalledWith(expect.stringContaining("/transactions/new?kind=expense"), { action: "replace" })
  })
})
