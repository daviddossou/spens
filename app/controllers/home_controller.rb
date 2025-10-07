class HomeController < ApplicationController
  # This will be renamed in the future to handle transaction data
  # For now, it manages the main authentication flow

  before_action :authenticate_user!, only: [:dashboard]

  def index
    # Landing page - redirect based on authentication status
    if user_signed_in?
      redirect_to dashboard_path
    else
      # Redirect unauthenticated users to Devise signup page
      redirect_to new_user_registration_path
    end
  end

  def dashboard
    # TODO: Add transaction data and analytics
  end
end
