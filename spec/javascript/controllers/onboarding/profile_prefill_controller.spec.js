import { describe, expect, it, vi } from "vitest"
import ProfilePrefillController from "../../../../app/javascript/controllers/onboarding/profile_prefill_controller"
import PickerController from "../../../../app/javascript/controllers/picker_controller"
import { startStimulus, flushStimulus } from "../../helpers/stimulus"

const picker = (field, value, rows) => `
  <div data-controller="picker" data-picker-rows-value='${JSON.stringify(rows)}' data-picker-placeholder-value="Choose">
    <input type="hidden" name="profile[${field}]" value="${value}" data-picker-target="input">
    <span data-picker-target="label"></span>
  </div>`

async function mount(html) {
  const application = await startStimulus("picker", PickerController, html)
  application.register("onboarding--profile-prefill", ProfilePrefillController)
  await flushStimulus()
  await flushStimulus()
  return application
}

describe("Onboarding ProfilePrefillController", () => {
  it("prefills a saved country and replaces the default currency", async () => {
    localStorage.setItem("spens:landing-country", JSON.stringify({ code: "BJ", cur: "XOF" }))
    const changed = vi.fn()
    document.addEventListener("change", changed)

    await mount(`
      <form data-controller="onboarding--profile-prefill">
        ${picker("country", "", [{ value: "BJ", label: "Benin" }])}
        ${picker("currency", "XOF", [{ value: "XOF", label: "XOF" }, { value: "EUR", label: "EUR" }])}
      </form>
    `)

    expect(document.querySelector("input[name*='country']").value).toBe("BJ")
    expect(document.querySelector("[name*='country']").parentElement.querySelector("[data-picker-target='label']").textContent).toBe("Benin")
    expect(document.querySelector("input[name*='currency']").value).toBe("XOF")
    expect(changed).toHaveBeenCalled()
    document.removeEventListener("change", changed)
  })

  it("preserves an existing user selection", async () => {
    localStorage.setItem("spens:landing-country", JSON.stringify({ code: "BJ", cur: "XOF" }))

    await mount(`
      <form data-controller="onboarding--profile-prefill">
        ${picker("country", "FR", [{ value: "FR", label: "France" }, { value: "BJ", label: "Benin" }])}
        ${picker("currency", "EUR", [{ value: "EUR", label: "EUR" }, { value: "XOF", label: "XOF" }])}
      </form>
    `)

    expect(document.querySelector("input[name*='country']").value).toBe("FR")
    expect(document.querySelector("input[name*='currency']").value).toBe("EUR")
  })

  it("ignores a saved value the picker does not list", async () => {
    localStorage.setItem("spens:landing-country", JSON.stringify({ code: "ZZ" }))

    await mount(`
      <form data-controller="onboarding--profile-prefill">
        ${picker("country", "", [{ value: "BJ", label: "Benin" }])}
      </form>
    `)

    expect(document.querySelector("input[name*='country']").value).toBe("")
  })
})
