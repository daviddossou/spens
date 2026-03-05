# frozen_string_literal: true

require "rails_helper"

RSpec.describe SpacesController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  before do
    sign_in user, scope: :user
  end

  describe "GET #index" do
    it "returns a successful response" do
      get spaces_path
      expect(response).to have_http_status(:success)
    end

    it "displays the user's spaces" do
      space.update!(name: "Personal")
      create(:space, user: user, name: "Business")

      get spaces_path
      expect(response.body).to include("Personal")
      expect(response.body).to include("Business")
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in page" do
        get spaces_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET #new" do
    it "returns a successful response" do
      get new_space_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new space" do
        expect {
          post spaces_path, params: { space: { name: "Business" } }
        }.to change(Space, :count).by(1)
      end

      it "sets the onboarding step" do
        post spaces_path, params: { space: { name: "Business" } }
        new_space = Space.find_by(name: "Business")
        expect(new_space.onboarding_current_step).to eq("onboarding_financial_goal")
      end

      it "sets the new space as current" do
        post spaces_path, params: { space: { name: "Business" } }
        new_space = Space.find_by(name: "Business")
        expect(session[:current_space_id]).to eq(new_space.id)
      end

      it "redirects to onboarding" do
        post spaces_path, params: { space: { name: "Business" } }
        expect(response).to redirect_to(onboarding_path)
      end
    end

    context "with invalid params" do
      it "does not create a space with blank name" do
        expect {
          post spaces_path, params: { space: { name: "" } }
        }.not_to change(Space, :count)
      end

      it "renders the new template" do
        post spaces_path, params: { space: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with duplicate name" do
      before { space.update!(name: "Personal") }

      it "does not create a duplicate space" do
        expect {
          post spaces_path, params: { space: { name: "Personal" } }
        }.not_to change(Space, :count)
      end
    end
  end

  describe "GET #edit" do
    it "returns a successful response" do
      get edit_space_path(id: space.id)
      expect(response).to have_http_status(:success)
    end

    it "sets @can_delete to false when only one space" do
      get edit_space_path(id: space.id)
      expect(assigns(:can_delete)).to be false
    end

    it "sets @can_delete to true when multiple spaces" do
      create(:space, user: user, name: "Other")
      get edit_space_path(id: space.id)
      expect(assigns(:can_delete)).to be true
    end

    context "with another user's space" do
      let(:other_user) { create(:user) }
      let(:other_space) { other_user.spaces.first }

      it "returns not found" do
        get edit_space_path(id: other_space.id)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH #update" do
    context "with valid params" do
      it "updates the space name" do
        patch space_path(id: space.id), params: { space: { name: "Updated" } }
        expect(space.reload.name).to eq("Updated")
      end

      it "updates currency and country" do
        patch space_path(id: space.id), params: { space: { currency: "EUR", country: "FR" } }
        space.reload
        expect(space.currency).to eq("EUR")
        expect(space.country).to eq("FR")
      end

      it "redirects to spaces index" do
        patch space_path(id: space.id), params: { space: { name: "Updated" } }
        expect(response).to redirect_to(spaces_path)
      end
    end

    context "with invalid params" do
      it "renders edit template" do
        patch space_path(id: space.id), params: { space: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE #destroy" do
    context "when user has multiple spaces" do
      let!(:other_space) { create(:space, user: user, name: "Other") }

      it "deletes the space" do
        expect {
          delete space_path(id: other_space.id)
        }.to change(Space, :count).by(-1)
      end

      it "redirects to spaces index" do
        delete space_path(id: other_space.id)
        expect(response).to redirect_to(spaces_path)
      end

      it "switches to another space if the deleted one was active" do
        # First, set the space as the active one
        post space_selection_path(space_id: space.id)
        expect(session[:current_space_id]).to eq(space.id)

        delete space_path(id: space.id)
        expect(session[:current_space_id]).to eq(other_space.id)
      end
    end

    context "when user has only one space" do
      it "does not delete the last space" do
        expect {
          delete space_path(id: space.id)
        }.not_to change(Space, :count)
      end

      it "redirects with alert" do
        delete space_path(id: space.id)
        expect(response).to redirect_to(spaces_path)
        expect(flash[:alert]).to be_present
      end
    end
  end
end
