# frozen_string_literal: true

# Thin wrapper around Brevo's contacts API. No-ops when no API key is configured and never
# raises — syncing a contact must not break a user-facing flow. Network work belongs in a job;
# use +upsert_contact_later+ from request code and let the job call +sync_contact+.
module Brevo
  module_function

  API_BASE = "https://api.brevo.com/v3"
  TIMEOUT = 5

  # Enqueue an upsert. Attributes map to Brevo contact attributes (e.g. FIRSTNAME, LASTNAME).
  def upsert_contact_later(email:, attributes: {})
    return if email.blank? || !enabled?

    BrevoContactSyncJob.perform_later(email, attributes.stringify_keys)
  end

  # Create or update a contact synchronously. Called from the job.
  def sync_contact(email, attributes = {})
    return if email.blank? || !enabled?

    body = { email: email, updateEnabled: true }
    body[:attributes] = attributes if attributes.present?
    body[:listIds] = config[:list_ids] if config[:list_ids].present?

    response = post_json("#{API_BASE}/contacts", body)
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.warn("[Brevo] upsert failed (#{response.code}): #{response.body}")
    end
    response
  rescue StandardError => e
    Rails.logger.warn("[Brevo] upsert failed: #{e.message}")
    nil
  end

  def enabled?
    config[:enabled]
  end

  def config
    Rails.application.config.x.brevo || {}
  end

  def post_json(url, body)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = http.read_timeout = TIMEOUT

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"
    request["api-key"] = config[:api_key]
    request.body = body.to_json

    http.request(request)
  end
end
