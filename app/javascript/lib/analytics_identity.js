// Keeps the PostHog identity honest across Turbo visits, where the head snippet does not re-run:
// - after sign-out the server drops a "ph_reset" cookie: forget the identity, so the next
//   visitor on this browser is not merged with the previous user;
// - a sign-in later in the same tab is identified again (meta "analytics-user");
// - while an admin impersonates (meta "analytics-muted"), capture is paused.
const meta = (name) => document.querySelector(`meta[name="${name}"]`)?.content

document.addEventListener("turbo:load", () => {
  const posthog = window.posthog
  if (!posthog?.capture) return

  if (document.cookie.includes("ph_reset=1")) {
    posthog.reset()
    document.cookie = "ph_reset=; Max-Age=0; path=/"
  }

  if (meta("analytics-muted")) return posthog.opt_out_capturing()
  if (posthog.has_opted_out_capturing?.()) posthog.opt_in_capturing({ captureEventName: false })

  const user = meta("analytics-user")
  if (user && posthog.get_distinct_id?.() !== user) posthog.identify(user)
})
