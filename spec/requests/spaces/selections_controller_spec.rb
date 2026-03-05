# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spaces::SelectionsController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  before do
    sign_in user, scope: :user
  end

  describe "POST #create" do
    context "with a valid space" do
      let!(:other_space) { create(:space, user: user, name: "Business") }

      it "sets the space as current" do
        post space_selection_path(space_id: other_space.id)
        expect(session[:current_space_id]).to eq(other_space.id)
      end

      it "redirects to dashboard" do
        post space_selection_path(space_id: other_space.id)
        expect(response).to redirect_to(dashboard_path)
      end

      it "sets a notice flash" do
        post space_selection_path(space_id: other_space.id)
        expect(flash[:notice]).to include("Business")
      end
    end

    context "with another user's space" do
      let(:other_user) { create(:user) }
      let(:other_space) { other_user.spaces.first }

      it "redirects to spaces index with alert" do
        post space_selection_path(space_id: other_space.id)
        expect(response).to redirect_to(spaces_path)
        expect(flash[:alert]).to be_present
      end

      it "does not change the current space" do
        post space_selection_path(space_id: other_space.id)
        expect(session[:current_space_id]).not_to eq(other_space.id)
      end
    end

    context "with a non-existent space" do
      it "redirects to spaces index with alert" do
        post space_selection_path(space_id: "non-existent-id")
        expect(response).to redirect_to(spaces_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in page" do
        post space_selection_path(space_id: space.id)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
