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
    Onboarding::StepNavigator.new(current_user).current_step_path
  end
end
