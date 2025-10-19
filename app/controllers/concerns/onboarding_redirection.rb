module OnboardingRedirection
  extend ActiveSupport::Concern

  included do
    before_action :redirect_to_onboarding, unless: :onboarding_redirection_exempt?
  end

  private

  def redirect_to_onboarding
    return unless user_signed_in?
    return if current_user.onboarding_completed?
    return if onboarding_controller?

    redirect_to onboarding_path
  end

  def onboarding_redirection_exempt?
    devise_controller? ||
    controller_name == "onboarding" || controller_name == "financial_goals" ||
    controller_name == "account_setup" || controller_name == "personal_info" ||
    controller_name == "rails/health" ||
    action_name == "destroy" # Allow sign out
  end

  def onboarding_controller?
    controller_name == "onboarding"
  end
end
