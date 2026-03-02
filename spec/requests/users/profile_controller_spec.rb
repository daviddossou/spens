# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::ProfileController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /profile/edit" do
    it "returns a successful response" do
      get edit_profile_path
      expect(response).to have_http_status(:success)
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in" do
        get edit_profile_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /profile" do
    it "updates the user profile" do
      patch profile_path, params: { user: { first_name: "Updated" } }
      expect(user.reload.first_name).to eq("Updated")
    end

    it "redirects to edit profile with a notice" do
      patch profile_path, params: { user: { first_name: "Updated" } }
      expect(response).to redirect_to(edit_profile_path)
    end

    it "updates email" do
      patch profile_path, params: { user: { email: "new@example.com" } }
      expect(user.reload.email).to eq("new@example.com")
    end

    context "with invalid parameters" do
      it "renders the form with errors" do
        patch profile_path, params: { user: { first_name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in" do
        patch profile_path, params: { user: { first_name: "Updated" } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "DELETE /profile" do
    it "destroys the user account" do
      expect {
        delete profile_path
      }.to change(User, :count).by(-1)
    end

    it "redirects to root path" do
      delete profile_path
      expect(response).to redirect_to(root_path)
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in" do
        delete profile_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
