# frozen_string_literal: true

# Cloudflare Turnstile on the public forms that create accounts or send OTP
# emails. Keys live in Rails credentials (turnstile.site_key, turnstile.secret_key);
# ENV overrides for local testing. Off unless both are set, so dev/test render no
# widget and every token check passes.
site_key = ENV["TURNSTILE_SITE_KEY"].presence || Rails.application.credentials.dig(:turnstile, :site_key)
secret_key = ENV["TURNSTILE_SECRET_KEY"].presence || Rails.application.credentials.dig(:turnstile, :secret_key)

Rails.application.config.x.turnstile = {
  site_key: site_key,
  secret_key: secret_key,
  enabled: site_key.present? && secret_key.present?
}
