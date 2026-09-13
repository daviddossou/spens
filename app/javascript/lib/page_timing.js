// Reports how long each page took to show, as a PostHog "page_render_ms" event, so the
// platform dashboards can split server time, network time and render time per platform.
//
// - initial load: navigation timing (TTFB, DOM ready) + the Server-Timing header;
// - Turbo visit: from turbo:visit to turbo:load, with the HTML fetch's resource timing;
// - preview: true when Turbo painted a cached snapshot before the fresh response.
const capture = (props) => window.posthog?.capture?.("page_render_ms", props)

// UUIDs and numeric ids collapse to ":id" so paths stay groupable.
const pattern = (path) =>
  path.replace(/^\/(en|fr)(?=\/|$)/, "").replace(/[0-9a-f]{8}-[0-9a-f-]{27}|\d+/g, ":id") || "/"

const serverMs = (entry) => {
  const timing = entry?.serverTiming?.find((t) => t.name === "process_action.action_controller")
  return timing ? Math.round(timing.duration) : undefined
}

let visitStartedAt = null
let preview = false

document.addEventListener("turbo:visit", () => { visitStartedAt = performance.now(); preview = false })
document.addEventListener("turbo:render", (event) => { if (event.detail?.isPreview) preview = true })

document.addEventListener("turbo:load", () => {
  const path = pattern(location.pathname)

  if (visitStartedAt === null) {
    const nav = performance.getEntriesByType("navigation")[0]
    if (!nav) return
    capture({
      path, kind: "initial",
      total_ms: Math.round(nav.domContentLoadedEventEnd), ttfb_ms: Math.round(nav.responseStart),
      server_ms: serverMs(nav), resources: performance.getEntriesByType("resource").length
    })
    return
  }

  const total = Math.round(performance.now() - visitStartedAt)
  const fetch = performance.getEntriesByType("resource")
    .filter((r) => r.initiatorType === "fetch" && new URL(r.name).pathname === location.pathname)
    .at(-1)
  capture({
    path, kind: "visit", total_ms: total, preview,
    ttfb_ms: fetch ? Math.round(fetch.responseStart - fetch.startTime) : undefined,
    server_ms: serverMs(fetch)
  })
  visitStartedAt = null
})
