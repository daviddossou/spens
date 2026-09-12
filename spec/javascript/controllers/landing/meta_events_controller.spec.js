import { describe, expect, it, vi } from "vitest"
import MetaEventsController from "../../../../app/javascript/controllers/landing/meta_events_controller"
import { startStimulus } from "../../helpers/stimulus"

describe("Landing MetaEventsController", () => {
  it("sends each lead placement only once to analytics and the backend", async () => {
    const fetch = vi.fn().mockResolvedValue({ ok: true })
    const fbq = vi.fn()
    const capture = vi.fn()
    vi.stubGlobal("fetch", fetch)
    window.fbq = fbq
    window.posthog = { capture }

    await startStimulus("landing--meta-events", MetaEventsController, `
      <meta name="csrf-token" content="csrf-1">
      <div data-controller="landing--meta-events"
           data-landing--meta-events-url-value="/events"
           data-landing--meta-events-page-value="welcome"
           data-landing--meta-events-events-value='{"view_content":"view-1","lead_hero":"lead-1"}'>
        <button data-action="landing--meta-events#lead"
                data-landing--meta-events-placement-param="hero">Download</button>
      </div>
    `)

    document.querySelector("button").click()
    document.querySelector("button").click()

    expect(fbq).toHaveBeenCalledOnce()
    expect(fbq).toHaveBeenCalledWith("track", "Lead", { content_name: "hero" }, { eventID: "lead-1" })
    expect(capture).toHaveBeenCalledWith("guide_download", { placement: "hero" })
    expect(fetch).toHaveBeenCalledOnce()
    expect(fetch).toHaveBeenCalledWith("/events", expect.objectContaining({
      method: "POST",
      body: JSON.stringify({ event: "lead_hero", placement: "hero" })
    }))
  })
})
