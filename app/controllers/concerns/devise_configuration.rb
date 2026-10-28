# frozen_string_literal: true

module DeviseConfiguration
  extend ActiveSupport::Concern
  # A link may have asked for a precise screen before sign-in.
  include ReturnPath

  included do
    before_action :configure_permitted_parameters, if: :devise_controller?
  end

  protected

  def after_sign_in_path_for(resource)
    consume_return_path || dashboard_path
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  private

  def configure_permitted_parameters
    # Account update params are handled by Users::ProfileController directly
    # This is kept for any remaining Devise controller compatibility
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name, :phone_number ])
  end
end
