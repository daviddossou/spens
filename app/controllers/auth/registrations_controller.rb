# frozen_string_literal: true

class Auth::RegistrationsController < ApplicationController
  layout "auth"
  before_action :redirect_if_signed_in, only: [ :new, :create ]

  def new
    @user = User.new(email: params[:email])
  end

  def create
    @user = User.new(registration_params)
    @user.password = SecureRandom.hex(32)

    if @user.save
      # Create default space (membership auto-created via callback)
      space = Space.create!(
        user: @user,
        name: I18n.t("spaces.default_name", default: "Personal"),
        onboarding_current_step: "onboarding_financial_goal"
      )

      # Accept pending invitation if present
      accepted_space = accept_pending_invitation(@user)

      @user.generate_otp!
      OtpMailer.send_otp(@user).deliver_later
      log_otp(@user) if Rails.env.development?

      session[:otp_user_id] = @user.id
      session[:otp_context] = "sign_up"
      # If joining via invitation, set the invited space as current (skip onboarding)
      session[:current_space_id] = accepted_space&.id || space.id
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

  def accept_pending_invitation(user)
    token = session.delete(:pending_invitation_token)
    return unless token

    invitation = Invitation.pending.find_by(token: token)
    return unless invitation

    invitation.accept!(user)
    invitation.space
  end

  def log_otp(user)
    Rails.logger.info "=" * 50
    Rails.logger.info "[OTP] Code for #{user.email}: #{user.otp_code}"
    Rails.logger.info "=" * 50
  end
end
