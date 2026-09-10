import { describe, expect, it } from "vitest"
import ProfileMenuController from "../../../../app/javascript/controllers/navigation/profile_menu_controller"
import { startStimulus } from "../../helpers/stimulus"

describe("Navigation ProfileMenuController", () => {
  it("opens from its toggle and closes on Escape", async () => {
    await startStimulus("navigation--profile-menu", ProfileMenuController, `
      <div data-controller="navigation--profile-menu">
        <button data-action="navigation--profile-menu#toggle">Menu</button>
        <nav data-navigation--profile-menu-target="menu"></nav>
        <div data-navigation--profile-menu-target="backdrop"></div>
      </div>
    `)
    const menu = document.querySelector("nav")
    const backdrop = document.querySelector("[data-navigation--profile-menu-target='backdrop']")

    document.querySelector("button").click()
    expect(menu).toHaveAttribute("data-visible")
    expect(backdrop).toHaveAttribute("data-visible")

    document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }))
    expect(menu).not.toHaveAttribute("data-visible")
    expect(backdrop).not.toHaveAttribute("data-visible")
  })
})
