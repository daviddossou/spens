# frozen_string_literal: true

# Thin wrapper around Meta's Conversions API. No-ops when not configured and never
# raises — tracking must not break a user-facing flow. Network work belongs in a job;
# use +send_event_later+ from request code and let MetaEventJob call +deliver+.
#
# Deduplication rule: event_id is always generated server-side (SecureRandom.uuid)
# and handed to the browser, so the pixel and CAPI sends carry the same id.
module Meta
  module_function

  API_VERSION = "v21.0"
  TIMEOUT = 5

  def send_event_later(event_name:, event_id:, user_data:, custom_data: {}, event_source_url: nil, action_source: "website")
    return unless capi_enabled?
    return if user_data.blank?

    event = {
      event_name: event_name,
      event_time: Time.current.to_i,
      event_id: event_id,
      action_source: action_source,
      user_data: user_data,
      custom_data: custom_data.presence,
      event_source_url: event_source_url
    }.compact

    MetaEventJob.perform_later(event.deep_stringify_keys)
  end

  # Builds the CAPI user_data payload. Personal fields are SHA-256 hashed,
  # lowercased and stripped; fbc/fbp/ip/user-agent go through in clear as Meta
  # expects. Nothing financial ever enters this payload.
  def user_data(user: nil, email: nil, request: nil, fbp: nil, fbc: nil, country: nil)
    {
      em: hash256(email || user&.email),
      ph: hash256(user&.phone_number.to_s.gsub(/\D/, "").presence),
      external_id: hash256(user&.id),
      fbp: fbp.presence,
      fbc: fbc.presence,
      client_ip_address: request&.remote_ip,
      client_user_agent: request&.user_agent,
      country: hash256(country)
    }.compact
  end

  def hash256(value)
    normalized = value.to_s.strip.downcase
    return nil if normalized.blank?

    Digest::SHA256.hexdigest(normalized)
  end

  # Synchronous POST to the Conversions API. Called from the job.
  def deliver(event)
    return unless capi_enabled?

    body = { data: [ event ], access_token: config[:capi_token] }
    body[:test_event_code] = config[:test_event_code] if config[:test_event_code]

    uri = URI("https://graph.facebook.com/#{API_VERSION}/#{config[:pixel_id]}/events")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = http.read_timeout = TIMEOUT

    request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
    request.body = body.to_json
    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.warn("[Meta] CAPI send failed (#{response.code}): #{response.body}")
    end
    response
  rescue StandardError => e
    Rails.logger.warn("[Meta] CAPI send failed: #{e.message}")
    nil
  end

  def pixel_enabled?
    config[:pixel_enabled]
  end

  def capi_enabled?
    config[:capi_enabled]
  end

  def pixel_id
    config[:pixel_id]
  end

  def config
    Rails.application.config.x.meta || {}
  end
end
