# frozen_string_literal: true

# Activation funnel milestones. Each one reaches PostHog at most once per user
# (ActivationMilestone ledger) as "activation_<name>", then Meta as "spens_<name>"
# when the user consented (Meta::Activation keeps its own ledger and gate).
module Activation
  module_function

  MILESTONES = %w[first_account first_transaction first_goal first_saving budget_complete month_2].freeze

  # `at` backdates the milestone (historical backfill); Meta only hears about live ones.
  def record(user, milestone, at: nil)
    milestone = milestone.to_s
    raise ArgumentError, "unknown activation milestone: #{milestone}" unless MILESTONES.include?(milestone)
    return unless user

    track(user, milestone, at)
    Meta::Activation.record(user, "spens_#{milestone}") unless at
  end

  def track(user, milestone, at)
    return if ActivationMilestone.exists?(user_id: user.id, name: milestone)

    ActivationMilestone.create!(user: user, name: milestone, created_at: at || Time.current)
    Analytics.track_at(at, user, "activation_#{milestone}", at ? { backfilled: true } : {})
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    # Raced with another request for the same milestone: already tracked.
  rescue StandardError => e
    Rails.logger.warn("[Activation] #{milestone} failed: #{e.message}")
  end
end
