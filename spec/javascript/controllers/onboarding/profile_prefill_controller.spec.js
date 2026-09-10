import { describe, expect, it, vi } from "vitest"
import ProfilePrefillController from "../../../../app/javascript/controllers/onboarding/profile_prefill_controller"
import { startStimulus } from "../../helpers/stimulus"

describe("Onboarding ProfilePrefillController", () => {
  it("prefills a saved country and replaces the default currency", async () => {
    localStorage.setItem("spens:landing-country", JSON.stringify({ code: "BJ", cur: "XOF" }))
    const changed = vi.fn()
    document.addEventListener("change", changed)

    await startStimulus("onboarding--profile-prefill", ProfilePrefillController, `
      <form data-controller="onboarding--profile-prefill">
        <select name="profile[country]"><option value=""></option><option value="BJ">Benin</option></select>
        <select name="profile[currency]"><option value="XOF">XOF</option><option value="EUR">EUR</option></select>
      </form>
    `)

    expect(document.querySelector("select[name*='country']").value).toBe("BJ")
    expect(document.querySelector("select[name*='currency']").value).toBe("XOF")
    expect(changed).toHaveBeenCalled()
    document.removeEventListener("change", changed)
  })

  it("preserves an existing user selection", async () => {
    localStorage.setItem("spens:landing-country", JSON.stringify({ code: "BJ", cur: "XOF" }))

    await startStimulus("onboarding--profile-prefill", ProfilePrefillController, `
      <form data-controller="onboarding--profile-prefill">
        <select name="profile[country]"><option value="FR" selected>France</option><option value="BJ">Benin</option></select>
        <select name="profile[currency]"><option value="EUR" selected>EUR</option><option value="XOF">XOF</option></select>
      </form>
    `)

    expect(document.querySelector("select[name*='country']").value).toBe("FR")
    expect(document.querySelector("select[name*='currency']").value).toBe("EUR")
  })
})
