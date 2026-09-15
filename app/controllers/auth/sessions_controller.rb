# frozen_string_literal: true

class Auth::SessionsController < ApplicationController
  include TurnstileProtection

  layout "auth"
  before_action :redirect_if_signed_in, only: [ :new, :create ]
  # Each submit sends an OTP email: keep bots from draining the mail quota.
  rate_limit to: 5, within: 10.minutes, only: :create, with: -> { rate_limited }
  protect_with_turnstile only: :create

  def new
    # Render email input form
  end

  def create
    email = params[:email]&.downcase&.strip
    user = User.find_by(email: email)

    if user
      user.generate_otp!
      OtpMailer.send_otp(user).deliver_later
      log_otp(user) if Rails.env.development?

      session[:otp_user_id] = user.id
      session[:otp_context] = "sign_in"
      redirect_to auth_verification_path
    else
      flash.now[:alert] = t("auth.sessions.user_not_found")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    sign_out if user_signed_in?
    redirect_to root_path, notice: t("devise.sessions.signed_out")
  end

  private

  def redirect_if_signed_in
    redirect_to dashboard_path if user_signed_in?
  end

  def rate_limited
    flash.now[:alert] = t("auth.rate_limited")
    render :new, status: :too_many_requests
  end

  def turnstile_failed
    render :new, status: :unprocessable_entity
  end

  def log_otp(user)
    Rails.logger.info "=" * 50
    Rails.logger.info "[OTP] Code for #{user.email}: #{user.otp_code}"
    Rails.logger.info "=" * 50
  end
end
