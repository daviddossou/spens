import { describe, expect, it } from "vitest"
import CalculatorController from "../../../app/javascript/controllers/savings_calculator_controller"
import { startStimulus } from "../helpers/stimulus"

describe("SavingsCalculatorController", () => {
  it("sanitizes income and calculates each savings projection", async () => {
    document.documentElement.lang = "en"
    await startStimulus("savings-calculator", CalculatorController, `
      <div data-controller="savings-calculator">
        <input value="12 000" data-savings-calculator-target="income" data-action="input->savings-calculator#compute">
        <input value="10" data-savings-calculator-target="slider">
        <span data-savings-calculator-target="pct"></span>
        <span data-savings-calculator-target="monthly"></span>
        <span data-savings-calculator-target="y1"></span>
        <span data-savings-calculator-target="y3"></span>
        <span data-savings-calculator-target="y10"></span>
      </div>
    `)

    expect(document.querySelector("input").value).toBe("12000")
    expect(document.querySelector("[data-savings-calculator-target='pct']")).toHaveTextContent("10 %")
    expect(document.querySelector("[data-savings-calculator-target='monthly']")).toHaveTextContent("1,200")
    expect(document.querySelector("[data-savings-calculator-target='y10']")).toHaveTextContent("144,000")
  })

  it("fills only the projections the page shows and groups the income as typed", async () => {
    document.documentElement.lang = "fr"
    await startStimulus("savings-calculator", CalculatorController, `
      <div data-controller="savings-calculator" data-savings-calculator-grouped-value="true">
        <input value="200000" data-savings-calculator-target="income">
        <input type="range" min="1" max="40" value="20" data-savings-calculator-target="slider">
        <span data-savings-calculator-target="pct"></span>
        <span data-savings-calculator-target="y1"></span>
        <span data-savings-calculator-target="y3"></span>
      </div>
    `)

    expect(document.querySelector("input").value).toBe("200\u00a0000")
    expect(document.querySelector("[data-savings-calculator-target='y1']").textContent).toBe("480\u00a0000")
    expect(document.querySelector("[data-savings-calculator-target='y3']").textContent).toBe("1\u00a0440\u00a0000")
    expect(document.querySelector("[type='range']").style.getPropertyValue("--fill")).toMatch(/^48\.7/)
  })
})
