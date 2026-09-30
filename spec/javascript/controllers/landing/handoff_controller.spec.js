import { describe, expect, it } from "vitest"
import HandoffController from "../../../../app/javascript/controllers/landing/handoff_controller"
import { startStimulus } from "../../helpers/stimulus"

const markup = `
  <div data-controller="landing--handoff">
    <button data-landing--diagnostic-target="card" class="is-checked" data-goals="save_regularly pay_off_debt"></button>
    <button data-landing--diagnostic-target="card" data-goals="track_spending"></button>
    <input data-savings-calculator-target="income" value="150000">
    <input type="range" data-savings-calculator-target="slider" value="10">
    <div data-onboarding--account-setup-target="accountLine">
      <input name="landing[transactions_attributes][0][account_name]" value=" Cash ">
      <input name="landing[transactions_attributes][0][amount]" value="1200">
    </div>
    <div data-onboarding--account-setup-target="accountLine">
      <input name="landing[transactions_attributes][1][account_name]" value="">
      <input name="landing[transactions_attributes][1][amount]" value="5">
    </div>
    <a id="signup" href="/fr/sign_up">Sign up</a>
    <a id="other" href="/fr/guide">Guide</a>
  </div>
`

const click = (id) => {
  const link = document.getElementById(id)
  link.addEventListener("click", (e) => e.preventDefault())
  link.click()
  return new URL(link.href, "http://spens.test")
}

describe("Landing HandoffController", () => {
  it("adds the picked country, the checked goals and the typed accounts to the sign-up link", async () => {
    localStorage.setItem("spens:landing-country", JSON.stringify({ code: "FR", cur: "EUR" }))
    await startStimulus("landing--handoff", HandoffController, markup)
    document.querySelector("[data-savings-calculator-target='income']").value = "250 000"

    const url = click("signup")

    expect(url.pathname).toBe("/fr/sign_up")
    expect(url.searchParams.get("landing[income]")).toBe("250000")
    expect(url.searchParams.has("landing[savings_rate]")).toBe(false)
    expect(url.searchParams.get("landing[country]")).toBe("FR")
    expect(url.searchParams.get("landing[currency]")).toBe("EUR")
    expect(url.searchParams.get("landing[goals]")).toBe("save_regularly,pay_off_debt")
    expect(url.searchParams.getAll("landing[accounts][][name]")).toEqual(["Cash"])
    expect(url.searchParams.getAll("landing[accounts][][amount]")).toEqual(["1200"])
  })

  it("leaves other links alone and skips a country that was only detected", async () => {
    await startStimulus("landing--handoff", HandoffController, markup)

    expect(click("other").search).toBe("")
    const url = click("signup")
    expect(url.searchParams.has("landing[country]")).toBe(false)
    expect(url.searchParams.get("landing[goals]")).toBe("save_regularly,pay_off_debt")
  })
})
