# frozen_string_literal: true

# PostHog product analytics. Capture is production-only; dev/test never load the JS snippet
# nor build a client. The project API key lives in Rails credentials (posthog.api_key) — it
# is public by design (shipped to the browser) but kept with the other keys for consistency.
# ENV vars act as an override/fallback. Host must match the project's cloud region: ours is
# US (PostHog assigned the region at org signup; wrong-region events are silently dropped).
api_key = ENV["POSTHOG_API_KEY"].presence || Rails.application.credentials.dig(:posthog, :api_key)

Rails.application.config.x.posthog = {
  api_key: api_key,
  host: ENV.fetch("POSTHOG_HOST", "https://us.i.posthog.com"),
  enabled: Rails.env.production? && api_key.present?
}

if Rails.application.config.x.posthog[:enabled]
  Rails.application.config.x.posthog_client = PostHog::Client.new(
    api_key: api_key,
    host: Rails.application.config.x.posthog[:host],
    on_error: proc { |status, msg| Rails.logger.warn("[PostHog] #{status}: #{msg}") }
  )

  at_exit { Rails.application.config.x.posthog_client.shutdown }
end
