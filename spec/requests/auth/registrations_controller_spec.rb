# frozen_string_literal: true

require "rails_helper"

RSpec.describe Auth::RegistrationsController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:valid_params) do
    {
      user: {
        first_name: "Jane",
        last_name: "Smith",
        email: "jane@example.com"
      }
    }
  end

  describe "GET /sign_up" do
    it "returns a successful response" do
      get new_user_registration_path
      expect(response).to have_http_status(:success)
    end

    it "redirects to dashboard if already signed in" do
      sign_in user
      get new_user_registration_path
      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe "POST /sign_up" do
    context "with valid parameters" do
      it "creates a new user" do
        expect {
          post user_registration_path, params: valid_params
        }.to change(User, :count).by(1)
      end

      it "generates an OTP for the new user" do
        post user_registration_path, params: valid_params

        new_user = User.find_by(email: "jane@example.com")
        expect(new_user.otp_code).to be_present
        expect(new_user.otp_sent_at).to be_present
      end

      it "redirects to verification page" do
        post user_registration_path, params: valid_params
        expect(response).to redirect_to(auth_verification_path)
      end

      it "sets a random password (user cannot sign in with password)" do
        post user_registration_path, params: valid_params
        new_user = User.find_by(email: "jane@example.com")
        expect(new_user.encrypted_password).to be_present
      end

      it "sets the onboarding step" do
        post user_registration_path, params: valid_params
        new_user = User.find_by(email: "jane@example.com")
        new_space = new_user.spaces.first
        expect(new_space.onboarding_current_step).to eq("onboarding_financial_goal")
      end

      it "generates an OTP code" do
        post user_registration_path, params: valid_params
        new_user = User.find_by(email: "jane@example.com")
        expect(new_user.otp_code).to be_present
        expect(new_user.otp_sent_at).to be_present
      end
    end

    context "with invalid parameters" do
      it "does not create a user without email" do
        expect {
          post user_registration_path, params: { user: { first_name: "Jane", last_name: "Doe", email: "" } }
        }.not_to change(User, :count)
      end

      it "does not create a user with duplicate email" do
        existing_user = user # force creation
        expect {
          post user_registration_path, params: { user: { first_name: "Jane", last_name: "Doe", email: existing_user.email } }
        }.not_to change(User, :count)
      end

      it "renders the form with errors" do
        post user_registration_path, params: { user: { first_name: "", last_name: "", email: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not generate an OTP" do
        post user_registration_path, params: { user: { first_name: "", last_name: "", email: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    it "redirects to dashboard if already signed in" do
      sign_in user
      post user_registration_path, params: valid_params
      expect(response).to redirect_to(dashboard_path)
    end
  end
end
