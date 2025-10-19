class OnboardingController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_if_completed

  # GET /onboarding
  def show
    redirect_to current_onboarding_step_path
  end

  private

  def redirect_if_completed
    redirect_to dashboard_path if current_user.onboarding_completed?
  end

  def current_onboarding_step_path
    case current_user.onboarding_current_step
    when "onboarding_financial_goal"
      onboarding_financial_goals_path
    when "onboarding_personal_info"
      onboarding_personal_info_path
    when "onboarding_account_setup"
      onboarding_account_setup_path
    else
      onboarding_financial_goals_path
    end
  end
end
