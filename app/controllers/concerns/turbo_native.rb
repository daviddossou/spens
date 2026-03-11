# frozen_string_literal: true

module TurboNative
  extend ActiveSupport::Concern

  included do
    helper_method :turbo_native_app?
  end

  def turbo_native_app?
    request.user_agent.to_s.include?("Turbo Native")
  end

  private

  # Rails 8 allow_browser uses an anonymous lambda before_action that calls
  # this private instance method. We override it here to skip the browser check
  # for Turbo Native requests (Android WebView may not pass the :modern check).
  # Note: in older Rails versions (<= 7), the named method
  # `check_browser_version_for_allow_browser` was called instead; this override
  # handles Rails 8+ correctly.
  def allow_browser(versions:, block:)
    return if turbo_native_app?

    super
  end
end
