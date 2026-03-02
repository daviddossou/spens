# frozen_string_literal: true

class Auth::VerificationsController < ApplicationController
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

      if context == "sign_up"
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

  def log_otp(user)
    Rails.logger.info "=" * 50
    Rails.logger.info "[OTP] Code for #{user.email}: #{user.otp_code}"
    Rails.logger.info "=" * 50
  end
end
