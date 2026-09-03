# frozen_string_literal: true

class Auth::VerificationsController < ApplicationController
  include InvitationAcceptance

  layout "auth"
  before_action :ensure_otp_session

  def show
    @email = otp_user&.email
  end

  def create
    user = otp_user

    if user&.verify_otp(params[:otp_code])
      context = session.delete(:otp_context)
      clear_otp_session
      sign_in(user)

      Analytics.identify(user)
      Analytics.track(user, context == "sign_up" ? "user_signed_up" : "user_signed_in")
      track_meta_conversion(user, context)

      accepted_space = accept_pending_invitation(user)

      if accepted_space
        set_current_space(accepted_space)
        redirect_to dashboard_path, notice: t("invitations.show.success")
      elsif context == "sign_up"
        redirect_to onboarding_path, notice: t("auth.registrations.signed_up")
      else
        redirect_to after_sign_in_path_for(user)
      end
    else
      @email = user&.email
      flash.now[:alert] = if user&.otp_expired?
                            t("auth.verifications.code_expired")
      else
                            t("auth.verifications.invalid_code")
      end
      render :show, status: :unprocessable_entity
    end
  end

  def resend
    user = otp_user

    if user
      user.generate_otp!
      OtpMailer.send_otp(user).deliver_later
      log_otp(user) if Rails.env.development?

      redirect_to auth_verification_path, notice: t("auth.verifications.code_resent")
    else
      redirect_to new_user_session_path, alert: t("auth.verifications.session_expired")
    end
  end

  private

  def otp_user
    @otp_user ||= User.find_by(id: session[:otp_user_id])
  end

  def ensure_otp_session
    unless session[:otp_user_id]
      redirect_to new_user_session_path, alert: t("auth.verifications.session_expired")
    end
  end

  def clear_otp_session
    session.delete(:otp_user_id)
    session.delete(:otp_context)
  end

  # Sign-up: CompleteRegistration on both channels — CAPI now, pixel queued for
  # the next page load, both with the same server-generated event_id.
  # Sign-in 30+ days after creation: spens_month_2, the retention milestone.
  def track_meta_conversion(user, context)
    if context == "sign_up"
      event_id = SecureRandom.uuid
      meta_send_server_event("CompleteRegistration", event_id: event_id, user: user)
      meta_queue_pixel_event("CompleteRegistration", event_id) if meta_consented?
    elsif user.created_at <= 30.days.ago
      Meta::Activation.record(user, :spens_month_2)
    end
  end

  def log_otp(user)
    Rails.logger.info "=" * 50
    Rails.logger.info "[OTP] Code for #{user.email}: #{user.otp_code}"
    Rails.logger.info "=" * 50
  end
end
