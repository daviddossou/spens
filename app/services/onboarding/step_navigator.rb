# frozen_string_literal: true

class Onboarding::StepNavigator
  # The financial goals step left the flow; a space parked on it restarts at the projection.
  STEP_PATHS = {
    "onboarding_savings_projection" => :onboarding_savings_projections_path,
    "onboarding_financial_goal" => :onboarding_savings_projections_path,
    "onboarding_profile_setup" => :onboarding_profile_setups_path,
    "onboarding_account_setup" => :onboarding_account_setups_path,
    "onboarding_first_day" => :onboarding_first_days_path,
    "onboarding_completed" => :dashboard_path
  }.freeze

  def initialize(space)
    @space = space
  end

  def current_step_path
    path_method = STEP_PATHS[@space.onboarding_current_step] || STEP_PATHS["onboarding_savings_projection"]

    if path_method
      Rails.application.routes.url_helpers.send(path_method)
    else
      Rails.application.routes.url_helpers.dashboard_path
    end
  end
end
