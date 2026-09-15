# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Turnstile on public auth forms", type: :request do
  let(:user) { create(:user) }
  let(:rejected) { Turnstile::Result.new(false, [ "invalid-input-response" ]) }
  let(:accepted) { Turnstile::Result.new(true, []) }

  describe "widget" do
    it "is absent when Turnstile is disabled" do
      get new_user_registration_path
      expect(response.body).not_to include('data-controller="turnstile"')
    end

    it "renders on sign-up and sign-in when enabled" do
      allow(Turnstile).to receive(:enabled?).and_return(true)
      allow(Turnstile).to receive(:site_key).and_return("site-key")

      get new_user_registration_path
      expect(response.body).to include('data-controller="turnstile"').and include("site-key")
      get new_user_session_path
      expect(response.body).to include('data-controller="turnstile"')
    end
  end

  describe "POST /sign_up" do
    let(:params) { { user: { first_name: "Jane", email: "jane@example.com" }, "cf-turnstile-response" => "tok" } }

    it "passes the token and the visitor IP to the check" do
      expect(Turnstile).to receive(:verify).with("tok", ip: "127.0.0.1").and_return(accepted)
      post user_registration_path, params: params
      expect(response).to redirect_to(onboarding_path)
    end

    it "re-renders the form with the typed values when the check fails" do
      allow(Turnstile).to receive(:verify).and_return(rejected)
      expect(Analytics).to receive(:track_anonymous).with("turnstile_failed", hash_including(error_codes: [ "invalid-input-response" ]))

      expect { post user_registration_path, params: params }.not_to change(User, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(I18n.t("auth.turnstile_failed")).and include("Jane")
    end
  end

  describe "POST /sign_in" do
    it "sends no OTP when the check fails" do
      allow(Turnstile).to receive(:verify).and_return(rejected)

      post user_session_path, params: { email: user.email }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(I18n.t("auth.turnstile_failed"))
      expect(user.reload.otp_code).to be_nil
    end
  end
end
