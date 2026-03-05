class OnboardingController < ApplicationController
  layout "onboarding"

  before_action :authenticate_user!
  before_action :redirect_if_completed, if: :user_signed_in?

  # GET /onboarding
  def show
    redirect_to current_onboarding_step_path
  end

  private

  def redirect_if_completed
    redirect_to dashboard_path if current_space&.onboarding_completed?
  end

  def current_onboarding_step_path
    Onboarding::StepNavigator.new(current_space).current_step_path
  end
end
