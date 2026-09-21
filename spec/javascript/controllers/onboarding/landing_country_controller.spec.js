import { afterEach, describe, expect, it } from "vitest"
import LandingCountryController from "../../../../app/javascript/controllers/onboarding/landing_country_controller"
import { startStimulus } from "../../helpers/stimulus"

const form = (confirmed = false) => `
  <form data-controller="onboarding--landing-country" data-onboarding--landing-country-confirmed-value="${confirmed}">
    <input type="hidden" name="landing_country" data-onboarding--landing-country-target="country">
    <input type="hidden" name="landing_currency" data-onboarding--landing-country-target="currency">
    <input type="hidden" name="time_zone" data-onboarding--landing-country-target="timeZone">
    <span data-onboarding--landing-country-target="code">XOF</span>
    <span data-onboarding--landing-country-target="symbol">FCFA</span>
  </form>`

const value = (name) => document.querySelector(`[name="${name}"]`).value
const text = (target) => document.querySelector(`[data-onboarding--landing-country-target="${target}"]`).textContent

describe("Onboarding LandingCountryController", () => {
  afterEach(() => localStorage.clear())

  it("carries the landing pick and shows its currency", async () => {
    localStorage.setItem("spens:landing-country", JSON.stringify({ code: "FR", cur: "EUR" }))

    await startStimulus("onboarding--landing-country", LandingCountryController, form())

    expect(value("landing_country")).toBe("FR")
    expect(value("landing_currency")).toBe("EUR")
    expect(text("code")).toBe("EUR")
    expect(text("symbol")).toBe("€")
    expect(value("time_zone")).not.toBe("")
  })

  it("leaves the server's guess alone without a landing pick", async () => {
    await startStimulus("onboarding--landing-country", LandingCountryController, form())

    expect(value("landing_country")).toBe("")
    expect(text("code")).toBe("XOF")
  })

  it("never overrides a space that already has its country", async () => {
    localStorage.setItem("spens:landing-country", JSON.stringify({ code: "FR", cur: "EUR" }))

    await startStimulus("onboarding--landing-country", LandingCountryController, form(true))

    expect(value("landing_country")).toBe("")
    expect(text("symbol")).toBe("FCFA")
  })
})
