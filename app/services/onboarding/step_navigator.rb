# frozen_string_literal: true

class Onboarding::StepNavigator
  STEP_PATHS = {
    'onboarding_financial_goal' => :onboarding_financial_goals_path,
    'onboarding_profile_setup' => :onboarding_profile_setups_path,
    'onboarding_account_setup' => :onboarding_account_setups_path,
    'onboarding_completed' => :dashboard_path
  }.freeze

  def initialize(user)
    @user = user
  end

  def current_step_path
    path_method = STEP_PATHS[@user.onboarding_current_step]

    if path_method
      Rails.application.routes.url_helpers.send(path_method)
    else
      Rails.application.routes.url_helpers.dashboard_path
    end
  end
end
