import { describe, expect, it } from "vitest"
import AccountKindController from "../../../app/javascript/controllers/account_kind_controller"
import { startStimulus } from "../helpers/stimulus"

const form = (manual = false) => `
  <div data-controller="account-kind" data-action="input->account-kind#infer"
       data-account-kind-names-value='["compte d&apos;epargne"]' data-account-kind-manual-value="${manual}"
       data-account-kind-everyday-value="everyday" data-account-kind-set-aside-value="set aside">
    <input name="account[account_name]">
    <input type="hidden" name="account[set_aside]" value="false" data-account-kind-target="input">
    <p data-account-kind-target="text">everyday</p>
    <button type="button" data-action="account-kind#toggle">Change</button>
  </div>`

const type = (value) => {
  const input = document.querySelector("[name='account[account_name]']")
  input.value = value
  input.dispatchEvent(new Event("input", { bubbles: true }))
}
const side = () => document.querySelector("[name='account[set_aside]']").value
const text = () => document.querySelector("p").textContent

describe("AccountKindController", () => {
  it("puts a savings name aside, whatever its emoji, case or accents", async () => {
    await startStimulus("account-kind", AccountKindController, form())

    type("💰 Compte d'Épargne")
    expect(side()).toBe("true")
    expect(text()).toBe("set aside")

    type("Mobile Money MTN")
    expect(side()).toBe("false")
    expect(text()).toBe("everyday")
  })

  it("keeps a manual choice over what the name suggests", async () => {
    await startStimulus("account-kind", AccountKindController, form())

    document.querySelector("button").click()
    expect(side()).toBe("true")

    type("Mobile Money MTN")
    expect(side()).toBe("true")
  })

  it("never re-guesses an account being edited", async () => {
    await startStimulus("account-kind", AccountKindController, form(true))

    type("Compte d'épargne")
    expect(side()).toBe("false")
  })
})
