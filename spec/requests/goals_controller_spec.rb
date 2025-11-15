# frozen_string_literal: true

require "rails_helper"

RSpec.describe GoalsController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:account) { create(:account, user: user, name: "Savings", balance: 1000.0, saving_goal: 5000.0) }

  before do
    sign_in user, scope: :user
  end

  describe "GET #index" do
    context "when user has accounts with goals" do
      let!(:account_with_goal) { create(:account, user: user, name: "Emergency Fund", saving_goal: 10000.0) }
      let!(:account_without_goal) { create(:account, user: user, name: "Checking", saving_goal: 0.0) }

      it "returns a successful response" do
        get goals_path
        expect(response).to have_http_status(:success)
      end

      it "displays accounts with saving goals" do
        get goals_path
        expect(response.body).to include("Emergency Fund")
      end

      it "doesn't display accounts without saving goals" do
        get goals_path
        expect(response.body).not_to include("Checking")
      end
    end

    context "when user has no accounts" do
      it "returns a successful response" do
        get goals_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in page" do
        get goals_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET #show" do
    context "with valid account" do
      it "returns a successful response" do
        get goal_path(id: account.id)
        expect(response).to have_http_status(:success)
      end

      it "displays account details" do
        get goal_path(id: account.id)
        expect(response.body).to include(account.name)
      end
    end

    context "with account from another user" do
      let(:other_user) { create(:user) }
      let(:other_account) { create(:account, user: other_user, name: "Other Account") }

      it "redirects to goals index" do
        get goal_path(id: other_account.id)
        expect(response).to redirect_to(goals_path)
      end

      it "sets an alert flash message" do
        get goal_path(id: other_account.id)
        expect(flash[:alert]).to eq(I18n.t('goals.errors.not_found'))
      end
    end

    context "with non-existent account id" do
      it "redirects to goals index" do
        get goal_path(id: 'non-existent-id')
        expect(response).to redirect_to(goals_path)
      end

      it "sets an alert flash message" do
        get goal_path(id: 'non-existent-id')
        expect(flash[:alert]).to eq(I18n.t('goals.errors.not_found'))
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in page" do
        get goal_path(id: account.id)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET #new" do
    it "returns a successful response" do
      get new_goal_path
      expect(response).to have_http_status(:success)
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in page" do
        get new_goal_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET #edit" do
    it "returns a successful response" do
      get edit_goal_path(id: account.id)
      expect(response).to have_http_status(:success)
    end

    it "displays account information" do
      get edit_goal_path(id: account.id)
      expect(response.body).to include(account.name)
    end

    context "with account from another user" do
      let(:other_user) { create(:user) }
      let(:other_account) { create(:account, user: other_user, name: "Other Account") }

      it "redirects to goals index" do
        get edit_goal_path(id: other_account.id)
        expect(response).to redirect_to(goals_path)
      end

      it "sets an alert flash message" do
        get edit_goal_path(id: other_account.id)
        expect(flash[:alert]).to eq(I18n.t('goals.errors.not_found'))
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in page" do
        get edit_goal_path(id: account.id)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST #create" do
    let(:valid_attributes) do
      {
        account_name: 'New Savings Account',
        current_balance: 500.00,
        saving_goal: 2000.00
      }
    end

    let(:invalid_attributes) do
      {
        account_name: '',
        current_balance: 100.00,
        saving_goal: 50.00 # Less than current_balance
      }
    end

    context "with valid parameters" do
      it "creates a new account or updates existing one" do
        post goals_path, params: { goal: valid_attributes }
        expect(response).to redirect_to(goals_path)
      end

      it "sets a success notice" do
        post goals_path, params: { goal: valid_attributes }
        expect(flash[:notice]).to eq(I18n.t('goals.create.success'))
      end

      context "when account doesn't exist" do
        it "creates a new account" do
          expect {
            post goals_path, params: { goal: valid_attributes }
          }.to change(Account, :count).by(1)
        end

        it "sets the correct saving goal" do
          post goals_path, params: { goal: valid_attributes }
          account = Account.find_by(name: 'New Savings Account', user: user)
          expect(account.saving_goal).to eq(2000.00)
        end

        it "adjusts the balance if different from current balance" do
          post goals_path, params: { goal: valid_attributes }
          account = Account.find_by(name: 'New Savings Account', user: user)
          expect(account.balance).to eq(500.00)
        end

        it "creates a new transaction to set the initial balance" do
          expect {
            post goals_path, params: { goal: valid_attributes }
          }.to change(Transaction, :count).by(1)
        end
      end

      context "when account already exists" do
        let!(:existing_account) { create(:account, user: user, name: 'Existing Account', balance: 1000.0, saving_goal: 3000.0) }

        it "does not create a new account" do
          expect {
            post goals_path, params: { goal: { account_name: 'Existing Account', current_balance: 1500.00, saving_goal: 4000.00 } }
          }.not_to change(Account, :count)
        end

        it "updates the saving goal" do
          post goals_path, params: { goal: { account_name: 'Existing Account', current_balance: 1500.00, saving_goal: 4000.00 } }
          expect(existing_account.reload.saving_goal).to eq(4000.00)
        end

        it "adjusts the balance if different from current balance" do
          post goals_path, params: { goal: { account_name: 'Existing Account', current_balance: 1500.00, saving_goal: 4000.00 } }
          expect(existing_account.reload.balance).to eq(1500.00)
        end

        it "creates a new transaction to adjust the balance if needed" do
          expect {
            post goals_path, params: { goal: { account_name: 'Existing Account', current_balance: 1500.00, saving_goal: 4000.00 } }
          }.to change(Transaction, :count).by(1)
        end

        it "doesn't create a transaction if balance is unchanged" do
          expect {
            post goals_path, params: { goal: { account_name: 'Existing Account', current_balance: 1000.00, saving_goal: 4000.00 } }
          }.not_to change(Transaction, :count)
        end
      end
    end

    context "with invalid parameters" do
      it "does not create an account" do
        expect {
          post goals_path, params: { goal: invalid_attributes }
        }.not_to change(Account, :count)
      end

      it "returns unprocessable entity status" do
        post goals_path, params: { goal: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      context "missing required fields" do
        it "fails without account_name" do
          attributes = valid_attributes.merge(account_name: '')
          post goals_path, params: { goal: attributes }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "fails without current_balance" do
          attributes = valid_attributes.dup
          attributes.delete(:current_balance)
          post goals_path, params: { goal: attributes }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "fails without saving_goal" do
          attributes = valid_attributes.dup
          attributes.delete(:saving_goal)
          post goals_path, params: { goal: attributes }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "validation errors" do
        it "fails when saving_goal is not greater than current_balance" do
          attributes = valid_attributes.merge(current_balance: 2000.00, saving_goal: 1000.00)
          post goals_path, params: { goal: attributes }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "fails when saving_goal is zero" do
          attributes = valid_attributes.merge(saving_goal: 0)
          post goals_path, params: { goal: attributes }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "fails when saving_goal is negative" do
          attributes = valid_attributes.merge(saving_goal: -100)
          post goals_path, params: { goal: attributes }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in page" do
        post goals_path, params: { goal: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end

      it "does not create an account" do
        sign_out user
        expect {
          post goals_path, params: { goal: valid_attributes }
        }.not_to change(Account, :count)
      end
    end

    context "when an error occurs during submission" do
      before do
        allow_any_instance_of(GoalForm).to receive(:submit).and_raise(StandardError.new("Database error"))
      end

      it "redirects to new goal path" do
        post goals_path, params: { goal: valid_attributes }
        expect(response).to redirect_to(new_goal_path)
      end

      it "sets an alert flash message" do
        post goals_path, params: { goal: valid_attributes }
        expect(flash[:alert]).to eq(I18n.t('goals.create.error'))
      end
    end
  end

  describe "PATCH #update" do
    let(:valid_update_attributes) do
      {
        account_name: account.name,
        current_balance: 1500.00,
        saving_goal: 6000.00
      }
    end

    let(:invalid_update_attributes) do
      {
        account_name: account.name,
        current_balance: 5000.00,
        saving_goal: 1000.00 # Less than current_balance
      }
    end

    context "with valid parameters" do
      it "updates the account goal" do
        patch goal_path(id: account.id), params: { goal: valid_update_attributes }
        expect(account.reload.saving_goal).to eq(6000.00)
      end

      it "redirects to the goal show page" do
        patch goal_path(id: account.id), params: { goal: valid_update_attributes }
        expect(response).to redirect_to(goal_path(id: account.id))
      end

      it "sets a success notice" do
        patch goal_path(id: account.id), params: { goal: valid_update_attributes }
        expect(flash[:notice]).to eq(I18n.t('goals.update.success'))
      end

      it "adjusts balance if needed" do
        patch goal_path(id: account.id), params: { goal: valid_update_attributes }
        expect(account.reload.balance).to eq(1500.00)
      end
    end

    context "with invalid parameters" do
      it "does not update the account" do
        original_goal = account.saving_goal
        patch goal_path(id: account.id), params: { goal: invalid_update_attributes }
        expect(account.reload.saving_goal).to eq(original_goal)
      end

      it "returns unprocessable entity status" do
        patch goal_path(id: account.id), params: { goal: invalid_update_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with account from another user" do
      let(:other_user) { create(:user) }
      let(:other_account) { create(:account, user: other_user, name: "Other Account") }

      it "redirects to goals index" do
        patch goal_path(id: other_account.id), params: { goal: valid_update_attributes }
        expect(response).to redirect_to(goals_path)
      end

      it "does not update the account" do
        original_goal = other_account.saving_goal
        patch goal_path(id: other_account.id), params: { goal: valid_update_attributes }
        expect(other_account.reload.saving_goal).to eq(original_goal)
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in page" do
        patch goal_path(id: account.id), params: { goal: valid_update_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end

      it "does not update the account" do
        sign_out user
        original_goal = account.saving_goal
        patch goal_path(id: account.id), params: { goal: valid_update_attributes }
        expect(account.reload.saving_goal).to eq(original_goal)
      end
    end

    context "when an error occurs during submission" do
      before do
        allow_any_instance_of(GoalForm).to receive(:submit).and_raise(StandardError.new("Database error"))
      end

      it "redirects to edit goal path" do
        patch goal_path(id: account.id), params: { goal: valid_update_attributes }
        expect(response).to redirect_to(edit_goal_path(account))
      end

      it "sets an alert flash message" do
        patch goal_path(id: account.id), params: { goal: valid_update_attributes }
        expect(flash[:alert]).to eq(I18n.t('goals.update.error'))
      end
    end
  end

  describe "parameter handling" do
    it "permits all required parameters" do
      params = {
        goal: {
          account_name: 'Test Account',
          current_balance: 100.00,
          saving_goal: 500.00,
          unpermitted_param: 'should be filtered'
        }
      }

      post goals_path, params: params
      expect(response).to have_http_status(:found)
    end
  end

  describe "edge cases" do
    let(:base_attributes) do
      {
        account_name: 'Edge Case Account',
        current_balance: 100.00,
        saving_goal: 500.00
      }
    end

    context "with very large amounts" do
      it "handles large goal values" do
        attributes = base_attributes.merge(current_balance: 1_000_000.00, saving_goal: 999_999_999.99)
        post goals_path, params: { goal: attributes }
        expect(response).to redirect_to(goals_path)
        expect(flash[:notice]).to be_present
      end
    end

    context "with special characters in account name" do
      it "handles special characters" do
        attributes = base_attributes.merge(account_name: "Spëçîål Sävings €$£ 🎉")
        post goals_path, params: { goal: attributes }
        expect(response).to redirect_to(goals_path)
        expect(flash[:notice]).to be_present
      end
    end

    context "with decimal precision" do
      it "handles many decimal places" do
        attributes = base_attributes.merge(current_balance: 100.123456, saving_goal: 500.789012)
        post goals_path, params: { goal: attributes }
        expect(response).to redirect_to(goals_path)
        expect(flash[:notice]).to be_present
      end
    end

    context "with case-insensitive account names" do
      let!(:existing_account) { create(:account, user: user, name: 'Savings Account', balance: 100.0, saving_goal: 1000.0) }

      it "finds existing account regardless of case" do
        expect {
          post goals_path, params: { goal: base_attributes.merge(account_name: 'SAVINGS ACCOUNT', saving_goal: 2000.00) }
        }.not_to change(Account, :count)
      end
    end
  end
end
