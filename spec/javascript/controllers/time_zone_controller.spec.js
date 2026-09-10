import { describe, expect, it, vi } from "vitest"
import TimeZoneController from "../../../app/javascript/controllers/time_zone_controller"
import { startStimulus } from "../helpers/stimulus"

describe("TimeZoneController", () => {
  it("patches a device time zone that differs from the saved value", async () => {
    vi.spyOn(Intl.DateTimeFormat.prototype, "resolvedOptions")
      .mockReturnValue({ timeZone: "Africa/Porto-Novo" })
    const fetch = vi.fn().mockResolvedValue({ ok: true })
    vi.stubGlobal("fetch", fetch)

    await startStimulus("time-zone", TimeZoneController, `
      <meta name="csrf-token" content="token-123">
      <div data-controller="time-zone"
           data-time-zone-current-value="UTC"
           data-time-zone-url-value="/settings/time-zone"></div>
    `)

    expect(fetch).toHaveBeenCalledWith("/settings/time-zone", {
      method: "PATCH",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": "token-123" },
      body: JSON.stringify({ time_zone: "Africa/Porto-Novo" })
    })
  })

  it("does nothing when the saved and device time zones match", async () => {
    vi.spyOn(Intl.DateTimeFormat.prototype, "resolvedOptions").mockReturnValue({ timeZone: "UTC" })
    const fetch = vi.fn()
    vi.stubGlobal("fetch", fetch)

    await startStimulus("time-zone", TimeZoneController, `
      <div data-controller="time-zone" data-time-zone-current-value="UTC" data-time-zone-url-value="/tz"></div>
    `)

    expect(fetch).not.toHaveBeenCalled()
  })
})
