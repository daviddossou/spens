import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="onboarding--financial-goals"
export default class extends Controller {
  connect() {
    // Defer so the ui--selectable-card controllers on the cards connect first.
    setTimeout(() => {
      this.preselectFromLanding()
      this.updateSubmitButton()
    }, 0)
    this.updateSubmitButton()

    // Listen for checkbox changes to update submit button
    this.element.addEventListener('change', (event) => {
      if (event.target.matches('input[type="checkbox"]')) {
        this.updateSubmitButton()
      }
    })
  }

  // Problems ticked on the landing diagnostic map to goals; pre-select them.
  preselectFromLanding() {
    let goals
    try {
      goals = JSON.parse(localStorage.getItem("spens:landing-goals"))
    } catch { return }
    if (!Array.isArray(goals) || goals.length === 0) return

    const boxes = [...this.element.querySelectorAll('input[type="checkbox"]')]
    if (boxes.some((b) => b.checked)) return // user already made choices

    goals.forEach((goal) => {
      const box = boxes.find((b) => b.value === goal)
      if (box && !box.checked) box.closest("[data-controller*='selectable-card']")?.click()
    })
    try { localStorage.removeItem("spens:landing-goals") } catch {}
  }

  updateSubmitButton() {
    const submitButton = this.element.querySelector('input[type="submit"], button[type="submit"]')
    const checkedBoxes = this.element.querySelectorAll('input[type="checkbox"]:checked')

    if (submitButton) {
      const hasSelection = checkedBoxes.length > 0
      submitButton.disabled = !hasSelection

      if (hasSelection) {
        submitButton.classList.remove('disabled')
      } else {
        submitButton.classList.add('disabled')
      }
    }
  }
}
