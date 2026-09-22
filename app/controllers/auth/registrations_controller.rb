# frozen_string_literal: true

class Auth::RegistrationsController < ApplicationController
  include InvitationAcceptance
  include TurnstileProtection

  layout "auth"
  before_action :redirect_if_signed_in, only: [ :new, :create ]
  rate_limit to: 5, within: 10.minutes, only: :create, with: -> { rate_limited }
  protect_with_turnstile only: :create

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

      # No OTP at sign-up: the address is confirmed at the start of the second
      # session instead (EmailConfirmation). Stamp this session so the gate
      # knows where the first one started.
      sign_in(@user)
      touch_session_activity

      Analytics.identify(@user)
      Analytics.track(@user, "user_signed_up", Analytics.acquisition_properties(@user).merge(invited: accepted_space.present?))
      track_meta_registration(@user)
      Brevo.upsert_contact_later(
        email: @user.email,
        attributes: { FIRSTNAME: @user.first_name, LASTNAME: @user.last_name }.compact_blank
      )
      WelcomeEmailJob.perform_later(@user, I18n.locale.to_s)

      # If joining via invitation, set the invited space as current (skip onboarding)
      if accepted_space
        set_current_space(accepted_space)
        redirect_to dashboard_path, notice: t("invitations.show.success")
      else
        session[:current_space_id] = space.id
        redirect_to onboarding_path, notice: t("auth.registrations.signed_up")
      end
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

  def rate_limited
    flash.now[:alert] = t("auth.rate_limited")
    render_form_again(:too_many_requests)
  end

  def turnstile_failed
    render_form_again(:unprocessable_entity)
  end

  def render_form_again(status)
    @user = User.new(params.fetch(:user, {}).permit(:first_name, :email))
    render :new, status: status
  end

  # CompleteRegistration on both channels — CAPI now, pixel queued for the next
  # page load, both with the same server-generated event_id.
  def track_meta_registration(user)
    event_id = SecureRandom.uuid
    meta_send_server_event("CompleteRegistration", event_id: event_id, user: user)
    meta_queue_pixel_event("CompleteRegistration", event_id) if meta_consented?
  end
end
