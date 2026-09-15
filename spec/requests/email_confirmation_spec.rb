# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Deferred email confirmation", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user, :unconfirmed) }
  let(:sign_up_params) { { user: { first_name: "Jane", email: "jane@example.com" } } }

  def sign_up
    post user_registration_path, params: sign_up_params
    User.find_by!(email: "jane@example.com")
  end

  it "lets the user browse freely during the sign-up session" do
    sign_up
    get onboarding_path
    expect(response).to have_http_status(:redirect)
    expect(response.location).to include("/onboarding/")

    travel 20.minutes
    get onboarding_path
    expect(response.location).to include("/onboarding/")
  end

  it "asks for the code at the start of the second session and keeps asking until confirmed" do
    new_user = sign_up

    travel(EmailConfirmation::SESSION_GAP + 1.minute)
    expect {
      get dashboard_path
    }.to have_enqueued_mail(OtpMailer, :send_otp)
    expect(response).to redirect_to(auth_verification_path)
    expect(new_user.reload.otp_code).to be_present

    get auth_verification_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include(I18n.t("auth.verifications.confirm_title"))

    # Still gated, and a valid code is not resent on every hit
    expect { get dashboard_path }.not_to have_enqueued_mail(OtpMailer, :send_otp)
    expect(response).to redirect_to(auth_verification_path)

    post auth_verification_path, params: { otp_code: new_user.reload.otp_code }
    expect(response).to redirect_to(dashboard_path)
    expect(new_user.reload).to be_confirmed

    get onboarding_path
    expect(response.location).to include("/onboarding/")
  end

  it "resends the code from the confirmation screen" do
    new_user = sign_up
    travel(EmailConfirmation::SESSION_GAP + 1.minute)
    get dashboard_path
    old_code = new_user.reload.otp_code

    post resend_otp_path
    expect(response).to redirect_to(auth_verification_path)
    expect(new_user.reload.otp_code).not_to eq(old_code)
  end

  it "drops the gate when the address was confirmed meanwhile" do
    new_user = sign_up
    travel(EmailConfirmation::SESSION_GAP + 1.minute)
    get dashboard_path

    new_user.confirm!
    get auth_verification_path
    expect(response).to redirect_to(dashboard_path)
    expect(flash[:notice]).to eq(I18n.t("auth.verifications.already_confirmed"))

    get onboarding_path
    expect(response.location).to include("/onboarding/")
  end

  it "still lets a gated user sign out" do
    sign_up
    travel(EmailConfirmation::SESSION_GAP + 1.minute)
    delete destroy_user_session_path
    expect(response).to redirect_to(root_path)
  end

  it "does not gate confirmed users" do
    sign_in create(:user)
    get dashboard_path
    expect(response).to have_http_status(:success)
  end

  it "gates an unconfirmed user whose session carries no activity stamp" do
    sign_in user
    get dashboard_path
    expect(response).to redirect_to(auth_verification_path)
  end
end
