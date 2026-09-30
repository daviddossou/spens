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

  # Contact attributes mirrored from the app so Brevo can segment on lifecycle, never on money.
  # They must exist as attributes in Brevo first (dates as YYYY-MM-DD).
  def lifecycle_attributes(user)
    space = user.owned_spaces.order(:created_at).first
    acquisition = user.acquisition || {}
    {
      FIRSTNAME: user.first_name,
      LASTNAME: user.last_name,
      SIGNED_UP_AT: user.created_at.to_date.iso8601,
      LAST_ACTIVE_AT: user.last_active_at&.to_date&.iso8601,
      LOCALE: space&.locale,
      COUNTRY: space&.country,
      SOURCE: acquisition["guide_link"].presence || acquisition["utm_source"].presence
    }.compact_blank
  end

  # Contact attributes every synced field needs on the Brevo side. Creating an existing one
  # answers 400 duplicate_parameter, which is the idempotent case.
  ATTRIBUTES = {
    "SIGNED_UP_AT" => "date", "LAST_ACTIVE_AT" => "date",
    "LOCALE" => "text", "COUNTRY" => "text", "SOURCE" => "text"
  }.freeze

  def ensure_attributes
    return unless enabled?

    ATTRIBUTES.each do |name, type|
      response = post_json("#{API_BASE}/contacts/attributes/normal/#{name}", { type: type })
      next if response.is_a?(Net::HTTPSuccess) || response.body.to_s.include?("duplicate_parameter")

      Rails.logger.warn("[Brevo] attribute #{name} not created (#{response.code}): #{response.body}")
    end
  rescue StandardError => e
    Rails.logger.warn("[Brevo] ensure_attributes failed: #{e.message}")
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
