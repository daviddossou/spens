module OnboardingRedirection
  extend ActiveSupport::Concern

  included do
    before_action :redirect_to_onboarding, unless: :onboarding_redirection_exempt?
  end

  private

  def redirect_to_onboarding
    return unless user_signed_in?
    return if current_space&.onboarding_completed?
    return if onboarding_controller?

    redirect_to onboarding_path
  end

  def onboarding_redirection_exempt?
    devise_controller? || controller_path.start_with?("auth/") || controller_name == "rails/health" ||
    controller_name == "invitations" ||
    controller_name == "legal" ||
    action_name == "destroy" # Allow sign out
  end

  # Steps 2 and 3 go through the app's real sheets: new account, new transaction.
  def onboarding_sheet?
    controller_path.in?(%w[accounts transactions]) && action_name.in?(%w[new create])
  end

  def onboarding_controller?
    controller_name == "onboarding" || controller_name == "savings_projections" ||
    controller_name == "financial_goals" ||
    controller_name == "profile_setups" || controller_name == "account_setups" ||
    controller_name == "first_days" || controller_name == "spaces" || onboarding_sheet?
  end
end
