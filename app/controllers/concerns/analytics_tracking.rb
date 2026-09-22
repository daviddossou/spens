# frozen_string_literal: true

# Fills the per-request analytics context (platform, locale, space) and auto-captures a
# PostHog event for every successful mutating request (POST/PATCH/PUT/DELETE) by any
# signed-in user, e.g. "budgets#create". Curated events (transaction_created,
# quick_add_used, ...) carry richer properties and are tracked explicitly in their controllers.
# "app_opened" fires once a day per browser: the retention baseline, since a long-lived
# session never goes through sign-in again. Nothing is sent while an admin impersonates.
module AnalyticsTracking
  extend ActiveSupport::Concern

  included do
    before_action :set_analytics_context
    before_action :track_app_opened
    before_action :track_email_return
    after_action :capture_analytics_event
  end

  private

  def set_analytics_context
    Analytics::Context.muted = respond_to?(:impersonating?, true) && impersonating?
    Analytics::Context.platform = analytics_platform
    Analytics::Context.locale = I18n.locale.to_s
    Analytics::Context.space_id = current_space&.id if respond_to?(:current_space, true) && user_signed_in?
  end

  def analytics_platform
    respond_to?(:turbo_native_app?, true) && turbo_native_app? ? "native" : "web"
  end

  # Read by lib/analytics_identity.js after sign-out: forget the PostHog identity on this browser.
  def reset_analytics_identity
    cookies[:ph_reset] = { value: "1", path: "/" }
  end

  def track_app_opened
    return unless request.get? && request.format.html? && !request.xhr?
    return unless respond_to?(:current_user, true) && current_user
    return if Analytics::Context.muted

    today = Date.current.iso8601
    return if session[:analytics_opened_on] == today

    session[:analytics_opened_on] = today
    Analytics.track(current_user, "app_opened")
  end

  # Set by EmailEventsController#click; fires on the first signed-in page after the click,
  # so a return that had to go through sign-in still counts.
  def track_email_return
    return unless session[:email_return] && request.get? && request.format.html?
    return unless respond_to?(:current_user, true) && current_user

    Analytics.track(current_user, "lifecycle_email_returned", email: session.delete(:email_return))
  end

  def capture_analytics_event
    return unless request.method.in?(%w[POST PATCH PUT DELETE])
    return unless response.successful? || response.redirection?
    return unless respond_to?(:current_user, true) && current_user

    Analytics.track(current_user, "#{controller_path}##{action_name}", method: request.method, status: response.status)
  end
end
