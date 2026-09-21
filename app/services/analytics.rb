# frozen_string_literal: true

# Thin wrapper around the PostHog client. No-ops when POSTHOG_API_KEY is unset and never
# raises — analytics must not break a user-facing request.
module Analytics
  module_function

  # First-touch attribution copied from users.acquisition onto the PostHog
  # person and the sign-up event, so ad performance reads through to activation.
  ACQUISITION_KEYS = %w[utm_source utm_medium utm_campaign utm_content guide_link landed_at].freeze

  # Per-request (or per-job) context merged into every event: platform (native app vs web),
  # locale and the space, which also becomes the PostHog "space" group. `muted` silences
  # everything (admin impersonation). Reset automatically between requests and jobs.
  class Context < ActiveSupport::CurrentAttributes
    attribute :platform, :locale, :space_id, :muted

    def properties
      { platform: platform, locale: locale, space_id: space_id }.compact
    end
  end

  def track(user, event, properties = {})
    track_at(nil, user, event, properties)
  end

  # Same event, dated `time` instead of now (historical backfills).
  def track_at(time, user, event, properties = {})
    return if Context.muted

    attrs = { distinct_id: distinct_id(user), event: event, properties: Context.properties.merge(properties) }
    attrs[:groups] = { space: Context.space_id } if Context.space_id
    attrs[:timestamp] = time if time
    client&.capture(attrs)
  rescue StandardError => e
    Rails.logger.warn("[Analytics] track failed: #{e.message}")
  end

  # Backfilled event that a re-run must not duplicate: the uuid is derived from `key`, and
  # PostHog collapses events sharing uuid, timestamp, event and person.
  def track_once(key, time, user, event, properties = {})
    client&.capture(distinct_id: distinct_id(user), event: event, timestamp: time,
                    uuid: Digest::UUID.uuid_v5(Digest::UUID::OID_NAMESPACE, "#{event}:#{key}"),
                    properties: properties.merge(backfilled: true))
  rescue StandardError => e
    Rails.logger.warn("[Analytics] track_once failed: #{e.message}")
  end

  def set_person(user, properties)
    client&.identify(distinct_id: distinct_id(user), properties: properties)
  rescue StandardError => e
    Rails.logger.warn("[Analytics] set_person failed: #{e.message}")
  end

  # Server-side event with nobody signed in (a bot check failing at sign-up);
  # no person profile so PostHog does not grow an "anonymous" person.
  def track_anonymous(event, properties = {})
    client&.capture(distinct_id: "anonymous", event: event,
                    properties: Context.properties.merge(properties, "$process_person_profile" => false))
  rescue StandardError => e
    Rails.logger.warn("[Analytics] track_anonymous failed: #{e.message}")
  end

  # Outcome of a quick-entry parse (kept / edited / deleted), the parser's accuracy signal.
  def track_quick_entry_resolved(attempt)
    Context.set(space_id: attempt.space_id, locale: Context.locale || attempt.locale) do
      track(attempt.user, "quick_entry_resolved",
            outcome: attempt.outcome, source: attempt.source, ai_used: attempt.ai_used?,
            corrected_fields: attempt.corrections&.keys || [])
    end
  end

  def identify(user)
    return if Context.muted

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

  def group_identify(space)
    return if Context.muted

    client&.group_identify(
      group_type: "space", group_key: space.id,
      properties: { name: space.name, locale: space.locale, created_at: space.created_at&.iso8601,
                    onboarding_step: space.onboarding_current_step, **onboarding_answers(space) }.compact
    )
  rescue StandardError => e
    Rails.logger.warn("[Analytics] group_identify failed: #{e.message}")
  end

  # What a space answered during onboarding. Nothing free-text, no amounts.
  def onboarding_answers(space)
    {
      financial_goals: space.financial_goals.presence, country: space.country, currency: space.currency,
      income_frequency: space.income_frequency, main_income_source: space.main_income_source,
      savings_rate: space.savings_rate
    }.compact
  end

  # The same answers as PostHog person properties, with one boolean per problem
  # ("goal_pay_off_debt") so a cohort or a breakdown needs no array matching.
  def onboarding_person_properties(space)
    chosen = Array(space.financial_goals)
    flags = Space::FINANCIAL_GOALS.to_h { |goal| [ "goal_#{goal}", chosen.include?(goal) ] }
    flags = {} if chosen.empty?

    { onboarding_step: space.onboarding_current_step, **onboarding_answers(space), **flags }
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
