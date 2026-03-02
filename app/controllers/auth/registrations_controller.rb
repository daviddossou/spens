# frozen_string_literal: true

class Auth::RegistrationsController < ApplicationController
  layout "auth"
  before_action :redirect_if_signed_in, only: [ :new, :create ]

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    @user.password = SecureRandom.hex(32)
    @user.onboarding_current_step = "onboarding_financial_goal"

    if @user.save
      @user.generate_otp!
      OtpMailer.send_otp(@user).deliver_later
      log_otp(@user) if Rails.env.development?

      session[:otp_user_id] = @user.id
      session[:otp_context] = "sign_up"
      redirect_to auth_verification_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:user).permit(:first_name, :last_name, :email)
  end

  def redirect_if_signed_in
    redirect_to dashboard_path if user_signed_in?
  end

  def log_otp(user)
    Rails.logger.info "=" * 50
    Rails.logger.info "[OTP] Code for #{user.email}: #{user.otp_code}"
    Rails.logger.info "=" * 50
  end
end
