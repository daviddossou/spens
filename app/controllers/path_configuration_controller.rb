# frozen_string_literal: true

class PathConfigurationController < ApplicationController
  # Skip authentication — native app fetches this at boot before signing in
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :redirect_if_onboarding_incomplete, raise: false

  def show
    render json: path_configuration
  end

  private

  def path_configuration
    {
      rules: [
        # Auth screens → modal bottom sheet (uri matches nav graph deep link)
        {
          patterns: [ "/sign_in", "/sign_up", "/verify" ],
          properties: { uri: "hotwire://fragment/modal/web" }
        },
        # Form screens → modal
        {
          patterns: [ ".*/new", ".*/edit" ],
          properties: { uri: "hotwire://fragment/modal/web" }
        },
        # Onboarding → replace (clears back stack so user can't go back)
        {
          patterns: [ "/onboarding.*" ],
          properties: { uri: "hotwire://fragment/web", pull_to_refresh_enabled: false }
        },
        # Default → standard full-screen push navigation
        {
          patterns: [ "/.*" ],
          properties: { uri: "hotwire://fragment/web", pull_to_refresh_enabled: true }
        }
      ]
    }
  end
end
