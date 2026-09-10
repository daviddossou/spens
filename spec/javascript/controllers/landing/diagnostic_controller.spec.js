import { describe, expect, it } from "vitest"
import DiagnosticController from "../../../../app/javascript/controllers/landing/diagnostic_controller"
import { startStimulus } from "../../helpers/stimulus"

const tiers = {
  none: { title: "None", line: "All clear" },
  low: { title: "Low", line: "A start" },
  mid: { title: "Mid", line: "Worth fixing" },
  high: { title: "High", line: "Act now" }
}

describe("Landing DiagnosticController", () => {
  it("tracks checked cards, updates the tier, and persists unique goals", async () => {
    await startStimulus("landing--diagnostic", DiagnosticController, `
      <div data-controller="landing--diagnostic" data-landing--diagnostic-tiers-value='${JSON.stringify(tiers)}'>
        <button data-landing--diagnostic-target="card" data-action="landing--diagnostic#toggle" data-goals="save budget"></button>
        <button data-landing--diagnostic-target="card" data-action="landing--diagnostic#toggle" data-goals="save debt"></button>
        <span data-landing--diagnostic-target="count"></span>
        <h2 data-landing--diagnostic-target="title"></h2>
        <p data-landing--diagnostic-target="line"></p>
      </div>
    `)

    document.querySelectorAll("button").forEach(button => button.click())

    expect(document.querySelector("[data-landing--diagnostic-target='count']")).toHaveTextContent("2")
    expect(document.querySelector("[data-landing--diagnostic-target='title']")).toHaveTextContent("Low")
    expect(JSON.parse(localStorage.getItem("spens:landing-goals"))).toEqual(["save", "budget", "debt"])
  })
})
