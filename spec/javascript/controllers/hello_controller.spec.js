import { describe, expect, it } from "vitest"
import HelloController from "../../../app/javascript/controllers/hello_controller"
import { startStimulus } from "../helpers/stimulus"

describe("HelloController", () => {
  it("renders its greeting when connected", async () => {
    await startStimulus("hello", HelloController, '<div data-controller="hello"></div>')

    expect(document.querySelector("[data-controller='hello']")).toHaveTextContent("Hello World!")
  })
})
