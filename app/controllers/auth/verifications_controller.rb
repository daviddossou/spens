# frozen_string_literal: true

class Auth::VerificationsController < ApplicationController
  include InvitationAcceptance

  layout "auth"
  before_action :ensure_otp_session
  before_action :skip_if_already_confirmed, if: :confirming_email?
  # 6-digit codes: cap guesses per IP; resends per IP and per pending user.
  rate_limit to: 10, within: 10.minutes, only: :create, with: -> { rate_limited }
  rate_limit to: 3, within: 10.minutes, only: :resend, with: -> { rate_limited }
  rate_limit to: 3, within: 10.minutes, only: :resend, name: "user", by: -> { session[:otp_user_id] }, with: -> { rate_limited }

  def show
    @email = otp_user&.email
    @confirming_email = confirming_email?
  end

  def create
    user = otp_user

    if user&.verify_otp(params[:otp_code])
      context = session.delete(:otp_context)
      clear_otp_session
      sign_in(user)
      # Entering a code proves the address, whichever flow asked for it.
      user.confirm!

      Analytics.identify(user)
      if context == "confirm_email"
        Analytics.track(user, "email_confirmed")
        redirect_to session.delete(:after_confirmation_path) || after_sign_in_path_for(user),
                    notice: t("auth.verifications.email_confirmed")
        return
      end

      Analytics.track(user, "user_signed_in")
      Meta::Activation.record(user, :spens_month_2) if user.created_at <= 30.days.ago

      accepted_space = accept_pending_invitation(user)

      if accepted_space
        set_current_space(accepted_space)
        redirect_to dashboard_path, notice: t("invitations.show.success")
      else
        redirect_to after_sign_in_path_for(user)
      end
    else
      @email = user&.email
      @confirming_email = confirming_email?
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
    session.delete(:email_confirmation_pending)
  end

  def confirming_email?
    session[:otp_context] == "confirm_email"
  end

  # Confirmed meanwhile (another tab, a sign-in on another device): nothing to
  # verify, drop the gate and carry on.
  def skip_if_already_confirmed
    return unless otp_user&.confirmed?

    clear_otp_session
    redirect_to session.delete(:after_confirmation_path) || after_sign_in_path_for(otp_user),
                notice: t("auth.verifications.already_confirmed")
  end

  def rate_limited
    @email = otp_user&.email
    @confirming_email = confirming_email?
    flash.now[:alert] = t("auth.rate_limited")
    render :show, status: :too_many_requests
  end

  def log_otp(user)
    Rails.logger.info "=" * 50
    Rails.logger.info "[OTP] Code for #{user.email}: #{user.otp_code}"
    Rails.logger.info "=" * 50
  end
end
