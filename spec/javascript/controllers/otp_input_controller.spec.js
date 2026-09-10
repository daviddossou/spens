import { describe, expect, it, vi } from "vitest"
import OtpInputController from "../../../app/javascript/controllers/otp_input_controller"
import { startStimulus } from "../helpers/stimulus"

const markup = `
  <form data-controller="otp-input">
    <input
      data-otp-input-target="input"
      data-action="input->otp-input#handleInput"
    >
  </form>
`

describe("OtpInputController", () => {
  it("focuses the OTP input when it connects", async () => {
    await startStimulus("otp-input", OtpInputController, markup)

    expect(document.activeElement).toBe(document.querySelector("input"))
  })

  it("keeps only the first six digits", async () => {
    await startStimulus("otp-input", OtpInputController, markup)
    const form = document.querySelector("form")
    const input = document.querySelector("input")
    form.requestSubmit = vi.fn()

    input.value = "12a34-567"
    input.dispatchEvent(new Event("input", { bubbles: true }))

    expect(input.value).toBe("123456")
  })

  it("submits the form when all six digits are entered", async () => {
    await startStimulus("otp-input", OtpInputController, markup)
    const form = document.querySelector("form")
    const input = document.querySelector("input")
    form.requestSubmit = vi.fn()

    input.value = "123456"
    input.dispatchEvent(new Event("input", { bubbles: true }))

    expect(form.requestSubmit).toHaveBeenCalledOnce()
  })
})
