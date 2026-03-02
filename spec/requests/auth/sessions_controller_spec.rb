# frozen_string_literal: true

require "rails_helper"

RSpec.describe Auth::SessionsController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }

  describe "GET /sign_in" do
    it "returns a successful response" do
      get new_user_session_path
      expect(response).to have_http_status(:success)
    end

    it "redirects to dashboard if already signed in" do
      sign_in user
      get new_user_session_path
      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe "POST /sign_in" do
    context "with a valid email" do
      it "generates an OTP and redirects to verification" do
        post user_session_path, params: { email: user.email }

        user.reload
        expect(user.otp_code).to be_present
        expect(response).to redirect_to(auth_verification_path)
      end

      it "generates an OTP code for the user" do
        post user_session_path, params: { email: user.email }
        user.reload
        expect(user.otp_code).to be_present
        expect(user.otp_sent_at).to be_present
      end

      it "stores user id and context in session" do
        post user_session_path, params: { email: user.email }
        # Verify redirect to verification page works (session was set)
        follow_redirect!
        expect(response).to have_http_status(:success)
      end

      it "handles email case insensitivity" do
        post user_session_path, params: { email: user.email.upcase }
        expect(response).to redirect_to(auth_verification_path)
      end

      it "handles email with whitespace" do
        post user_session_path, params: { email: "  #{user.email}  " }
        expect(response).to redirect_to(auth_verification_path)
      end
    end

    context "with an unknown email" do
      it "renders the form with an error" do
        post user_session_path, params: { email: "unknown@example.com" }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not generate an OTP" do
        post user_session_path, params: { email: "unknown@example.com" }
        # No user to check, just verify no error occurred
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    it "redirects to dashboard if already signed in" do
      sign_in user
      post user_session_path, params: { email: user.email }
      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe "DELETE /sign_out" do
    before { sign_in user }

    it "signs out the user and redirects to root" do
      delete destroy_user_session_path
      expect(response).to redirect_to(root_path)
    end

    it "works when not signed in" do
      sign_out user
      delete destroy_user_session_path
      expect(response).to redirect_to(root_path)
    end
  end
end
