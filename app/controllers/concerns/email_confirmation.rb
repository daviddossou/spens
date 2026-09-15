# frozen_string_literal: true

# Sign-up no longer asks for an OTP: the user lands in the app right away and
# proves the address at the start of their *second* session instead. A session
# boundary is a gap of SESSION_GAP since the last request (the sign-up session
# stamps `last_seen_at`; a fresh sign-in already goes through the OTP and
# confirms). Once the gate opens it stays shut, on every page, until the code
# is entered on /verify (context "confirm_email").
module EmailConfirmation
  extend ActiveSupport::Concern

  SESSION_GAP = 30.minutes

  included do
    before_action :require_email_confirmation, unless: :email_confirmation_exempt?
  end

  private

  def require_email_confirmation
    return unless user_signed_in?
    return if current_user.confirmed? || impersonating?

    if session[:email_confirmation_pending] || new_session_started?
      start_email_confirmation(current_user)
      session[:after_confirmation_path] = request.fullpath if request.get? && !request.xhr?
      redirect_to auth_verification_path
    else
      touch_session_activity
    end
  end

  def new_session_started?
    last_seen = session[:last_seen_at]
    last_seen.blank? || Time.zone.parse(last_seen) < SESSION_GAP.ago
  end

  def touch_session_activity
    session[:last_seen_at] = Time.current.iso8601
  end

  # Reuses the OTP screen; a still-valid code is not resent on every gated hit.
  def start_email_confirmation(user)
    unless session[:email_confirmation_pending]
      session[:email_confirmation_pending] = true
      flash[:notice] = t("auth.verifications.confirm_email_prompt")
    end

    unless user.otp_code.present? && !user.otp_expired?
      user.generate_otp!
      OtpMailer.send_otp(user).deliver_later
      Rails.logger.info "[OTP] Code for #{user.email}: #{user.otp_code}" if Rails.env.development?
    end

    session[:otp_user_id] = user.id
    session[:otp_context] = "confirm_email"
  end

  def email_confirmation_exempt?
    devise_controller? ||
      controller_path.start_with?("auth/") ||
      controller_name.in?(%w[health path_configuration legal impersonations time_zones])
  end
end
