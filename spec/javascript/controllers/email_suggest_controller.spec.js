import { describe, expect, it } from "vitest"
import EmailSuggestController from "../../../app/javascript/controllers/email_suggest_controller"
import { startStimulus } from "../helpers/stimulus"

const form = `
  <form data-controller="email-suggest" data-email-suggest-message-value="Did you mean %{email}?">
    <input type="email" data-email-suggest-target="input"
           data-action="blur->email-suggest#check input->email-suggest#hide">
    <p hidden data-email-suggest-target="hint">
      <span data-email-suggest-target="before"></span><button type="button"
        data-email-suggest-target="suggestion" data-action="email-suggest#accept"></button><span data-email-suggest-target="after"></span>
    </p>
  </form>`

const input = () => document.querySelector("input")
const hint = () => document.querySelector("p")
const type = (value) => {
  input().value = value
  input().dispatchEvent(new Event("input", { bubbles: true }))
  input().dispatchEvent(new Event("blur"))
}

describe("EmailSuggestController", () => {
  it("offers the fix on blur and applies it on tap", async () => {
    await startStimulus("email-suggest", EmailSuggestController, form)

    type("ama@gmial.com")
    expect(hint().hidden).toBe(false)
    expect(hint().textContent.replace(/\s+/g, " ").trim()).toBe("Did you mean ama@gmail.com?")

    document.querySelector("button").click()
    expect(input().value).toBe("ama@gmail.com")
    expect(hint().hidden).toBe(true)
  })

  it("stays quiet for a known or unknown domain and hides while typing", async () => {
    await startStimulus("email-suggest", EmailSuggestController, form)

    type("ama@gmail.com")
    expect(hint().hidden).toBe(true)

    type("ama@gmial.com")
    input().value = "ama@gmial.co"
    input().dispatchEvent(new Event("input", { bubbles: true }))
    expect(hint().hidden).toBe(true)

    type("ama@anka.africa")
    expect(hint().hidden).toBe(true)
  })
})
