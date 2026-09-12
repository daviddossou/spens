import { describe, expect, it } from "vitest"
import FinancialGoalsController from "../../../../app/javascript/controllers/onboarding/financial_goals_controller"
import { startStimulus } from "../../helpers/stimulus"

describe("Onboarding FinancialGoalsController", () => {
  it("enables and relabels submit after a goal is selected", async () => {
    await startStimulus("onboarding--financial-goals", FinancialGoalsController, `
      <form data-controller="onboarding--financial-goals"
            data-onboarding--financial-goals-empty-label-value="Choose a goal"
            data-onboarding--financial-goals-ready-label-value="Continue">
        <input type="checkbox" value="save">
        <button type="submit">Continue</button>
      </form>
    `)
    const checkbox = document.querySelector("input")
    const submit = document.querySelector("button")

    expect(submit).toBeDisabled()
    expect(submit).toHaveTextContent("Choose a goal")

    checkbox.click()
    expect(submit).toBeEnabled()
    expect(submit).toHaveTextContent("Continue")
  })
})
