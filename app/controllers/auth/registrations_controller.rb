# frozen_string_literal: true

class Auth::RegistrationsController < ApplicationController
  include InvitationAcceptance

  layout "auth"
  before_action :redirect_if_signed_in, only: [ :new, :create ]

  def new
    @user = User.new(email: params[:email])
  end

  def create
    @user = User.new(registration_params)
    @user.password = SecureRandom.hex(32)
    # First-touch attribution (utm_*, fbclid, guide_link) + marketing consent and
    # Meta cookies, frozen at creation so later CAPI events keep their source.
    @user.acquisition = (session[:meta_first_touch] || {}).merge(
      "consent" => meta_consented?,
      "fbp" => cookies[:_fbp],
      "fbc" => meta_fbc
    ).compact_blank

    if @user.save
      # Create default space (membership auto-created via callback)
      space = Space.create!(
        user: @user,
        name: I18n.t("spaces.default_name", default: "Personal"),
        locale: I18n.locale.to_s,
        onboarding_current_step: "onboarding_financial_goal"
      )

      # Accept pending invitation if present
      accepted_space = accept_pending_invitation(@user)

      @user.generate_otp!
      OtpMailer.send_otp(@user).deliver_later
      log_otp(@user) if Rails.env.development?

      Analytics.track(@user, "sign_up_submitted", invited: accepted_space.present?)
      Brevo.upsert_contact_later(
        email: @user.email,
        attributes: { FIRSTNAME: @user.first_name, LASTNAME: @user.last_name }.compact_blank
      )

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
    params.require(:user).permit(:first_name, :email)
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
