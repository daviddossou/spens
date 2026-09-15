# frozen_string_literal: true

# Gates an action behind a Turnstile token. Controllers override
# turnstile_failed to re-render their form; the default answers 422.
module TurnstileProtection
  extend ActiveSupport::Concern

  class_methods do
    def protect_with_turnstile(**options)
      before_action :require_turnstile, **options
    end
  end

  private

  def require_turnstile
    result = Turnstile.verify(params["cf-turnstile-response"], ip: request.remote_ip)
    return if result.success?

    Analytics.track_anonymous("turnstile_failed", error_codes: result.error_codes, path: request.path)
    flash.now[:alert] = t("auth.turnstile_failed")
    turnstile_failed
  end

  def turnstile_failed
    head :unprocessable_entity
  end
end
