# frozen_string_literal: true

# PostHog events of the onboarding funnel. Every step reports viewed / completed / failed,
# and what the user answered rides along: the problems they came to solve, their country and
# income, the accounts they opened. Answers from the user's first space are also written on
# the PostHog person, so retention and activation can be broken down by them later.
module OnboardingTracking
  extend ActiveSupport::Concern

  private

  def track_onboarding_step_viewed(step)
    Analytics.track(current_user, "onboarding_step_viewed", onboarding_base_properties.merge(step: step))
  end

  def track_onboarding_step_failed(step, form)
    Analytics.track(current_user, "onboarding_step_failed",
                    onboarding_base_properties.merge(step: step, errors: form.errors.attribute_names.map(&:to_s)))
  end

  def track_onboarding_step_completed(step, properties = {})
    Analytics.group_identify(current_space)
    Analytics.track(current_user, "onboarding_step_completed",
                    onboarding_base_properties.merge(step: step, **properties).merge(onboarding_person_set))
  end

  # One event per chosen problem: PostHog breaks down a plain string, not an array.
  def track_onboarding_goals(goals, from_landing:)
    goals.each do |goal|
      Analytics.track(current_user, "onboarding_goal_chosen",
                      onboarding_base_properties.merge(goal: goal, from_landing: from_landing.include?(goal)))
    end
  end

  def track_onboarding_completed(properties = {})
    Analytics.track(current_user, "onboarding_completed", onboarding_base_properties.merge(
      Analytics.onboarding_answers(current_space),
      minutes_since_signup: ((Time.current - current_user.created_at) / 60).round,
      **properties
    ))
  end

  def onboarding_base_properties
    { first_space: onboarding_first_space? }
  end

  # A second space (side project, shared budget) goes through onboarding too; only the first
  # one describes the person.
  def onboarding_first_space?
    return @onboarding_first_space if defined?(@onboarding_first_space)

    @onboarding_first_space = current_user.owned_spaces.order(:created_at).pick(:id) == current_space.id
  end

  def onboarding_person_set
    return {} unless onboarding_first_space?

    { "$set" => Analytics.onboarding_person_properties(current_space.reload) }
  end
end
