import { describe, expect, it } from "vitest"
import ConsentController from "../../../app/javascript/controllers/consent_controller"
import { startStimulus } from "../helpers/stimulus"

describe("ConsentController", () => {
  it("stores a denial and removes the banner", async () => {
    await startStimulus("consent", ConsentController, `
      <aside data-controller="consent"><button data-action="consent#decline">Decline</button></aside>
    `)

    document.querySelector("button").click()

    expect(document.cookie).toContain("mkt_consent=denied")
    expect(document.querySelector("aside")).not.toBeInTheDocument()
  })
})
