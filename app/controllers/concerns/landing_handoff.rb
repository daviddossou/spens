# frozen_string_literal: true

# What the visitor chose on the landing page (country, diagnostic, accounts) rides along
# the sign-up link as `landing[...]` params and is kept in the session, so it survives the
# jump from an in-app browser to the real one. Auth::RegistrationsController applies it to
# the new space; the latest visit wins.
module LandingHandoff
  extend ActiveSupport::Concern

  SESSION_KEY = :landing_choices

  included do
    before_action :capture_landing_choices, if: -> { request.get? && params[:landing].present? }
  end

  private

  def capture_landing_choices
    choices = Onboarding::LandingChoices.from_params(params[:landing])
    session[SESSION_KEY] = choices.to_h if choices.any?
  end

  def consume_landing_choices
    Onboarding::LandingChoices.new(session.delete(SESSION_KEY))
  end
end
