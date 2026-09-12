import { describe, expect, it, vi } from "vitest"
import AccountsController from "../../../../app/javascript/controllers/landing/accounts_controller"
import { startStimulus } from "../../helpers/stimulus"

const markup = `
  <form data-controller="landing--accounts">
    <div data-onboarding--account-setup-target="accountLine">
      <span class="form-input-addon--prepend"></span>
      <input name="accounts[0][account_name]" value="Cash">
      <input name="accounts[0][amount]" value="1200">
    </div>
    <div data-onboarding--account-setup-target="accountLine">
      <span class="form-input-addon--prepend"></span>
      <input name="accounts[1][account_name]" value="Bank">
      <input name="accounts[1][amount]" value="300">
    </div>
    <strong data-landing--accounts-target="total"></strong>
    <div data-landing--accounts-target="recap"><a href="/sign-up">Continue</a></div>
    <p data-landing--accounts-target="note"></p>
    <button type="button" data-action="landing--accounts#save">Save</button>
  </form>
`

describe("Landing AccountsController", () => {
  it("calculates the total and reveals its recap", async () => {
    document.documentElement.lang = "en"
    vi.stubGlobal("requestAnimationFrame", callback => callback())
    await startStimulus("landing--accounts", AccountsController, markup)

    expect(document.querySelector("[data-landing--accounts-target='total']")).toHaveTextContent("1,500")
    expect(document.querySelector("[data-landing--accounts-target='recap']").hidden).toBe(false)
    expect(document.querySelector("[data-landing--accounts-target='note']").hidden).toBe(false)
  })

  it("persists non-empty account rows", async () => {
    vi.stubGlobal("requestAnimationFrame", callback => callback())
    await startStimulus("landing--accounts", AccountsController, markup)

    document.querySelector("button").click()

    expect(JSON.parse(localStorage.getItem("spens:landing-accounts"))).toEqual([
      { name: "Cash", amount: "1200" },
      { name: "Bank", amount: "300" }
    ])
  })
})
