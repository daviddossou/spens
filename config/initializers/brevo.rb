# frozen_string_literal: true

# Brevo contacts sync. Brevo is also our SMTP relay (see production.rb), but that only sends
# mail — pushing people into Brevo's contact lists needs the transactional API. The API key
# lives in Rails credentials (brevo.api_key); ENV overrides for local/staging. Off unless a
# key is present, so dev/test never hit the network. BREVO_LIST_ID optionally drops every
# synced contact into a list.
api_key = ENV["BREVO_API_KEY"].presence || Rails.application.credentials.dig(:brevo, :api_key)

Rails.application.config.x.brevo = {
  api_key: api_key,
  list_ids: ENV["BREVO_LIST_ID"].to_s.split(",").filter_map { |id| Integer(id, exception: false) },
  enabled: api_key.present?
}
