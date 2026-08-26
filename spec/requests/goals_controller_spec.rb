# frozen_string_literal: true

require "rails_helper"

RSpec.describe GoalsController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  before { sign_in user, scope: :user }

  def create_goal(name:, account_name:, target: nil)
    account = create(:account, space: space, name: account_name)
    create(:goal, space: space, account: account, name: name, target_amount: target)
  end

  describe "GET #index" do
    it "lists goals by their name" do
      create_goal(name: "Trip to Zanzibar", account_name: "Travel")
      get goals_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Trip to Zanzibar")
    end
  end

  describe "GET #new" do
    it "renders the form" do
      get new_goal_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      { goal: { goal_name: "Trip to Zanzibar", account_name: "Travel Fund", current_balance: 1_000, target_amount: 5_000 } }
    end

    it "creates a goal and its account" do
      expect { post goals_path, params: valid_params }
        .to change(Goal, :count).by(1).and change(Account, :count).by(1)
      expect(response).to have_http_status(:see_other)

      goal = space.goals.order(:created_at).last
      expect(goal.name).to eq("Trip to Zanzibar")
      expect(goal.target_amount).to eq(5_000)
    end

    it "creates a goal without a target amount" do
      params = { goal: valid_params[:goal].except(:target_amount) }
      expect { post goals_path, params: params }.to change(Goal, :count).by(1)
      expect(space.goals.order(:created_at).last.target_amount).to be_nil
    end

    it "fails without a goal name" do
      params = { goal: valid_params[:goal].except(:goal_name) }
      expect { post goals_path, params: params }.not_to change(Goal, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH #update" do
    it "updates the goal for the account" do
      goal = create_goal(name: "Old name", account_name: "Travel", target: 5_000)

      patch goal_path(id: goal.account_id),
            params: { goal: { goal_name: "New name", account_name: "Travel", target_amount: 8_000 } }

      expect(response).to have_http_status(:see_other)
      expect(goal.reload.name).to eq("New name")
      expect(goal.target_amount).to eq(8_000)
    end
  end

  describe "GET #show" do
    it "shows the goal by name" do
      goal = create_goal(name: "Trip to Zanzibar", account_name: "Travel")
      get goal_path(id: goal.account_id)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Trip to Zanzibar")
    end
  end

  describe "authentication" do
    it "redirects when signed out" do
      sign_out user
      get goals_path
      expect(response).to have_http_status(:redirect)
    end
  end
end
