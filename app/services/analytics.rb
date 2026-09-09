# frozen_string_literal: true

# Thin wrapper around the PostHog client. No-ops when POSTHOG_API_KEY is unset and never
# raises — analytics must not break a user-facing request.
module Analytics
  module_function

  # First-touch attribution copied from users.acquisition onto the PostHog
  # person and the sign-up event, so ad performance reads through to activation.
  ACQUISITION_KEYS = %w[utm_source utm_medium utm_campaign utm_content guide_link landed_at].freeze

  def track(user, event, properties = {})
    client&.capture(distinct_id: distinct_id(user), event: event, properties: properties)
  rescue StandardError => e
    Rails.logger.warn("[Analytics] track failed: #{e.message}")
  end

  def identify(user)
    client&.identify(
      distinct_id: distinct_id(user),
      properties: {
        email: user.email, first_name: user.first_name, created_at: user.created_at&.iso8601,
        **acquisition_properties(user)
      }
    )
  rescue StandardError => e
    Rails.logger.warn("[Analytics] identify failed: #{e.message}")
  end

  def acquisition_properties(user)
    user.try(:acquisition)&.slice(*ACQUISITION_KEYS) || {}
  end

  def distinct_id(user)
    "user_#{user.id}"
  end

  def client
    client = Rails.application.config.x.posthog_client
    client.is_a?(PostHog::Client) ? client : nil
  end
end
