# frozen_string_literal: true

class Onboarding::StepNavigator
  # Sign-up is step 1. The projection, goals, profile and account steps left the flow: a
  # space parked on any of them goes on to its first day.
  STEP_PATHS = {
    "onboarding_savings_projection" => :onboarding_first_days_path,
    "onboarding_financial_goal" => :onboarding_first_days_path,
    "onboarding_profile_setup" => :onboarding_first_days_path,
    "onboarding_account_setup" => :onboarding_first_days_path,
    "onboarding_first_day" => :onboarding_first_days_path,
    "onboarding_balances" => :onboarding_balances_path,
    "onboarding_summary" => :onboarding_summaries_path,
    "onboarding_completed" => :dashboard_path
  }.freeze

  def initialize(space)
    @space = space
  end

  def current_step_path
    path_method = STEP_PATHS[@space.onboarding_current_step] || STEP_PATHS["onboarding_first_day"]

    if path_method
      Rails.application.routes.url_helpers.send(path_method)
    else
      Rails.application.routes.url_helpers.dashboard_path
    end
  end
end
