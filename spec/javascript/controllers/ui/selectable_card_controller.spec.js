import { describe, expect, it, vi } from "vitest"
import SelectableCardController from "../../../../app/javascript/controllers/ui/selectable_card_controller"
import { startStimulus } from "../../helpers/stimulus"

describe("UI SelectableCardController", () => {
  it("toggles a checkbox and dispatches its change event", async () => {
    await startStimulus("ui--selectable-card", SelectableCardController, `
      <div data-controller="ui--selectable-card" data-action="click->ui--selectable-card#toggle">
        <input type="checkbox" data-ui--selectable-card-target="checkbox">
        <span>Card</span>
      </div>
    `)
    const card = document.querySelector("[data-controller='ui--selectable-card']")
    const input = document.querySelector("input")
    const changed = vi.fn()
    input.addEventListener("change", changed)

    card.querySelector("span").click()

    expect(input.checked).toBe(true)
    expect(card).toHaveClass("selected")
    expect(card).toHaveAttribute("data-selected", "true")
    expect(changed).toHaveBeenCalledOnce()
  })

  it("keeps one radio card selected within a group", async () => {
    await startStimulus("ui--selectable-card", SelectableCardController, `
      <div data-controller="ui--selectable-card" data-action="click->ui--selectable-card#toggle">
        <input type="radio" name="goal" checked data-ui--selectable-card-target="radio">
        <span>First</span>
      </div>
      <div data-controller="ui--selectable-card" data-action="click->ui--selectable-card#toggle">
        <input type="radio" name="goal" data-ui--selectable-card-target="radio">
        <span>Second</span>
      </div>
    `)
    const cards = document.querySelectorAll("[data-controller='ui--selectable-card']")

    cards[1].querySelector("span").click()

    expect(cards[0]).not.toHaveClass("selected")
    expect(cards[1]).toHaveClass("selected")
    expect(cards[1].querySelector("input").checked).toBe(true)
  })
})
