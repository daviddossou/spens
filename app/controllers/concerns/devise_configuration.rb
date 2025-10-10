# frozen_string_literal: true

# Concern to handle all Devise-related configuration
# This keeps Devise logic separate from general application logic
module DeviseConfiguration
  extend ActiveSupport::Concern

  included do
    # Configure Devise to permit additional parameters
    before_action :configure_permitted_parameters, if: :devise_controller?
  end

  protected

  # Override Devise's after_sign_in_path to redirect to dashboard
  def after_sign_in_path_for(resource)
    dashboard_path
  end

  # Override Devise's after_sign_out_path to redirect to home
  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name, :phone_number ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name, :phone_number ])
  end
end
