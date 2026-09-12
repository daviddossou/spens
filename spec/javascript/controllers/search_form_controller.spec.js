import { describe, expect, it, vi } from "vitest"
import SearchFormController from "../../../app/javascript/controllers/search_form_controller"
import { startStimulus } from "../helpers/stimulus"

const markup = `
  <form data-controller="search-form" data-search-form-delay-value="250">
    <input data-search-form-target="input" data-action="input->search-form#search" value="">
    <button type="button" class="hidden" data-search-form-target="clear" data-action="search-form#clear">Clear</button>
  </form>
`

describe("SearchFormController", () => {
  it("debounces submission and exposes the clear button", async () => {
    await startStimulus("search-form", SearchFormController, markup)
    const form = document.querySelector("form")
    const input = document.querySelector("input")
    const clear = document.querySelector("button")
    form.requestSubmit = vi.fn()
    vi.useFakeTimers()

    input.value = "rent"
    input.dispatchEvent(new Event("input", { bubbles: true }))

    expect(clear).not.toHaveClass("hidden")
    expect(form.requestSubmit).not.toHaveBeenCalled()
    vi.advanceTimersByTime(250)
    expect(form.requestSubmit).toHaveBeenCalledOnce()
  })

  it("clears, focuses, and submits the input", async () => {
    await startStimulus("search-form", SearchFormController, markup)
    const form = document.querySelector("form")
    const input = document.querySelector("input")
    form.requestSubmit = vi.fn()
    input.value = "rent"

    document.querySelector("button").click()

    expect(input.value).toBe("")
    expect(document.activeElement).toBe(input)
    expect(form.requestSubmit).toHaveBeenCalledOnce()
  })
})
