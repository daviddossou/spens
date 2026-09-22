# frozen_string_literal: true

# Open pixel and tracked link of the lifecycle e-mails. Bare controller: image proxies and
# link scanners send user agents that allow_browser would turn away.
class EmailEventsController < ActionController::Base
  EMAILS = %w[welcome].freeze
  PIXEL = Base64.decode64("R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7")
  SCANNERS = /bot|crawl|spider|preview|scan|proofpoint|mimecast|barracuda/i

  def open
    track("lifecycle_email_opened", proxy: image_proxy) if tracked_user
    response.headers["Cache-Control"] = "no-store"
    send_data PIXEL, type: "image/gif", disposition: "inline"
  end

  # The return itself is tracked by AnalyticsTracking once the user is signed in.
  def click
    if tracked_user && !request.user_agent.to_s.match?(SCANNERS)
      track("lifecycle_email_clicked")
      session[:email_return] = email
    end

    redirect_to dashboard_path(locale: params[:locale], utm_source: "spens", utm_medium: "email", utm_campaign: email)
  end

  private

  def email
    params[:email].presence_in(EMAILS)
  end

  def tracked_user
    @tracked_user ||= email && User.find_signed(params[:token], purpose: :email_events)
  end

  def track(event, properties = {})
    Analytics.track(tracked_user, event, { email: email }.merge(properties))
  end

  # Apple Mail preloads every image whether or not the e-mail is read, so those opens are
  # flagged to be left out. Gmail's proxy fetches at the real open.
  def image_proxy
    agent = request.user_agent.to_s
    return "gmail" if agent.include?("GoogleImageProxy")
    return "apple" if agent.strip == "Mozilla/5.0"

    "none"
  end
end
