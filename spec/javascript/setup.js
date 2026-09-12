import "@testing-library/jest-dom/vitest"
import { afterEach, vi } from "vitest"
import { flushStimulus, stopStimulusApplications } from "./helpers/stimulus"

afterEach(async () => {
  vi.useRealTimers()

  try {
    document.body.innerHTML = ""
    await flushStimulus()
    stopStimulusApplications()
  } finally {
    document.body.removeAttribute("class")
    document.documentElement.removeAttribute("lang")
    document.cookie.split(";").forEach(cookie => {
      document.cookie = `${cookie.split("=")[0].trim()}=; Max-Age=0; path=/`
    })
    localStorage.clear()
    sessionStorage.clear()
    vi.restoreAllMocks()
    vi.unstubAllGlobals()
    delete window.fbq
    delete window.posthog
  }
})
