# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # Set minimum password length for all actions that need it
  before_action :set_minimum_password_length, only: [ :new, :create, :edit, :update ]

  protected

  def after_sign_up_path_for(resource)
    resource.update!(onboarding_current_step: "onboarding_financial_goal")
    onboarding_path
  end

  private

  # Set the minimum password length for form validation hints
  def set_minimum_password_length
    @minimum_password_length = User.validators_on(:password)
                                   .find { |v| v.kind == :length }&.options&.dig(:minimum) || 6
  end

  # Customize sign up parameters to include additional fields
  def sign_up_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
  end

  # Customize account update parameters to include additional fields
  def account_update_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation, :current_password)
  end
end
