# frozen_string_literal: true

# Server-only Meta activation events — the spens_* funnel milestones that have no
# browser equivalent. Each fires at most once per user (MetaConversion ledger),
# only for users who consented to marketing tracking at registration. No event_id
# handoff to the browser: nothing to deduplicate on these.
module Meta
  module Activation
    module_function

    EVENTS = %w[
      spens_first_account
      spens_first_transaction
      spens_first_goal
      spens_first_saving
      spens_budget_complete
      spens_month_2
    ].freeze

    def record(user, event_name)
      event_name = event_name.to_s
      raise ArgumentError, "unknown Meta activation event: #{event_name}" unless EVENTS.include?(event_name)
      return unless Meta.capi_enabled?
      return unless user&.meta_consented?
      return if MetaConversion.exists?(user_id: user.id, event_name: event_name)

      conversion = MetaConversion.create!(user: user, event_name: event_name, event_id: SecureRandom.uuid)
      Meta.send_event_later(
        event_name: event_name,
        event_id: conversion.event_id,
        user_data: Meta.user_data(user: user, fbp: user.acquisition["fbp"], fbc: user.acquisition["fbc"]),
        action_source: "website"
      )
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      # Raced with another request for the same milestone: already sent, nothing to do.
    rescue StandardError => e
      Rails.logger.warn("[Meta] activation #{event_name} failed: #{e.message}")
    end
  end
end
