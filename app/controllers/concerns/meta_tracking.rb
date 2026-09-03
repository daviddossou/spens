# frozen_string_literal: true

# Meta Pixel + Conversions API plumbing for controllers.
#
# - Captures first-touch attribution (utm_*, fbclid, guide_link) into the session
#   on first visit; Auth::RegistrationsController attaches it to the user.
# - Issues server-generated event_ids (the deduplication key shared by pixel and
#   CAPI sends) and hands them to the browser via views.
# - Queues pixel events in session for pages rendered after a server-side send
#   (e.g. CompleteRegistration fires CAPI in the verify request and the pixel
#   call on the next page load).
#
# Everything is gated on the marketing-consent cookie: no consent, no send —
# server-side included.
module MetaTracking
  extend ActiveSupport::Concern

  CONSENT_COOKIE = :mkt_consent
  FIRST_TOUCH_PARAMS = %w[utm_source utm_medium utm_campaign utm_content fbclid guide_link].freeze

  included do
    before_action :meta_capture_first_touch, if: -> { request.get? }
    helper_method :meta_consent_state, :meta_pixel_queue!
  end

  private

  # "granted", "denied" or nil (undecided).
  def meta_consent_state
    cookies[CONSENT_COOKIE].presence_in(%w[granted denied])
  end

  def meta_consented?
    meta_consent_state == "granted"
  end

  def meta_capture_first_touch
    return if session[:meta_first_touch].present?

    touched = params.permit(*FIRST_TOUCH_PARAMS).to_h.compact_blank
    return if touched.empty?

    session[:meta_first_touch] = touched.merge("landed_at" => Time.current.iso8601)
  end

  # Server-generated UUID for one event occurrence, remembered in session so the
  # beacon endpoint (MetaEventsController) can send CAPI with the very same id
  # the pixel used. Reissued per page render.
  def meta_issue_event_id(key)
    ids = (session[:meta_event_ids] ||= {})
    ids[key.to_s] = SecureRandom.uuid
  end

  def meta_consume_event_id(key)
    session[:meta_event_ids]&.delete(key.to_s)
  end

  # fbc: prefer the pixel's _fbc cookie, else derive from a fbclid param/first touch.
  def meta_fbc
    return cookies[:_fbc] if cookies[:_fbc].present?

    fbclid = params[:fbclid].presence || session[:meta_first_touch]&.dig("fbclid")
    "fb.1.#{(Time.current.to_f * 1000).to_i}.#{fbclid}" if fbclid.present?
  end

  def meta_user_data(user: nil, email: nil)
    Meta.user_data(user: user, email: email, request: request, fbp: cookies[:_fbp], fbc: meta_fbc)
  end

  def meta_send_server_event(event_name, event_id:, user: nil, email: nil, custom_data: {})
    return unless meta_consented?

    Meta.send_event_later(
      event_name: event_name,
      event_id: event_id,
      user_data: meta_user_data(user: user, email: email),
      custom_data: custom_data,
      event_source_url: request.original_url
    )
  end

  # Pixel events to fire on the next rendered page (fbq call with the same
  # event_id as the CAPI send already made server-side).
  def meta_queue_pixel_event(event_name, event_id)
    (session[:meta_pixel_queue] ||= []) << { "name" => event_name, "id" => event_id }
  end

  # Drains the queue; called by the pixel partial while rendering.
  def meta_pixel_queue!
    session.delete(:meta_pixel_queue) || []
  end
end
