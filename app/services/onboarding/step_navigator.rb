# frozen_string_literal: true

class Onboarding::StepNavigator
  STEP_PATHS = {
    'onboarding_financial_goal' => :onboarding_personal_info_path,
    'onboarding_personal_info' => :onboarding_account_setup_path,
    'onboarding_account_setup' => :dashboard_path
  }.freeze

  def initialize(user)
    @user = user
  end

  def next_step_path
    path_method = STEP_PATHS[@user.onboarding_current_step]

    if path_method
      Rails.application.routes.url_helpers.send(path_method)
    else
      Rails.application.routes.url_helpers.dashboard_path
    end
  end
end
