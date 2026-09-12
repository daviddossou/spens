import { describe, expect, it } from "vitest"
import CalculatorController from "../../../../app/javascript/controllers/landing/calculator_controller"
import { startStimulus } from "../../helpers/stimulus"

describe("Landing CalculatorController", () => {
  it("sanitizes income and calculates each savings projection", async () => {
    document.documentElement.lang = "en"
    await startStimulus("landing--calculator", CalculatorController, `
      <div data-controller="landing--calculator">
        <input value="12 000" data-landing--calculator-target="income" data-action="input->landing--calculator#compute">
        <input value="10" data-landing--calculator-target="slider">
        <span data-landing--calculator-target="pct"></span>
        <span data-landing--calculator-target="monthly"></span>
        <span data-landing--calculator-target="y1"></span>
        <span data-landing--calculator-target="y3"></span>
        <span data-landing--calculator-target="y10"></span>
      </div>
    `)

    expect(document.querySelector("input").value).toBe("12000")
    expect(document.querySelector("[data-landing--calculator-target='pct']")).toHaveTextContent("10 %")
    expect(document.querySelector("[data-landing--calculator-target='monthly']")).toHaveTextContent("1,200")
    expect(document.querySelector("[data-landing--calculator-target='y10']")).toHaveTextContent("144,000")
  })
})
