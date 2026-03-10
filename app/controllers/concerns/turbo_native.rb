# frozen_string_literal: true

module TurboNative
  extend ActiveSupport::Concern

  included do
    helper_method :turbo_native_app?
  end

  def turbo_native_app?
    request.user_agent.to_s.include?("Turbo Native")
  end

  # Override Rails' allow_browser check to skip it for Turbo Native requests.
  # Android WebView may not satisfy :modern in all environments (older emulators,
  # devices with outdated system WebView). Native apps are always trusted.
  def check_browser_version_for_allow_browser
    return if turbo_native_app?

    super
  end
end
