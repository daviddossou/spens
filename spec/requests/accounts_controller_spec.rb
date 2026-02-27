# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccountsController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:account) { create(:account, user: user, name: "Savings", balance: 1000.0, saving_goal: 5000.0) }

  before do
    sign_in user, scope: :user
  end

  describe "GET #index" do
    context "when user has accounts" do
      let!(:account1) { create(:account, user: user, name: "Savings") }
      let!(:account2) { create(:account, user: user, name: "Checking") }

      it "returns a successful response" do
        get accounts_path
        expect(response).to have_http_status(:success)
      end

      it "displays accounts" do
        get accounts_path
        expect(response.body).to include("Savings")
        expect(response.body).to include("Checking")
      end
    end

    context "when user has accounts with saving goals" do
      let!(:account_with_goal) { create(:account, user: user, name: "Goal Account", saving_goal: 10000.0) }
      let!(:account_without_goal) { create(:account, user: user, name: "No Goal", saving_goal: 0.0) }

      it "displays both accounts" do
        get accounts_path
        expect(response.body).to include("Goal Account")
        expect(response.body).to include("No Goal")
      end
    end

    context "when user has no accounts" do
      it "returns a successful response" do
        get accounts_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in page" do
        get accounts_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET #show" do
    context "with valid account" do
      it "returns a successful response" do
        get account_path(id: account.id)
        expect(response).to have_http_status(:success)
      end

      it "displays account details" do
        get account_path(id: account.id)
        expect(response.body).to include(account.name)
      end
    end

    context "with account from another user" do
      let(:other_user) { create(:user) }
      let(:other_account) { create(:account, user: other_user, name: "Other Account") }

      it "redirects to accounts index" do
        get account_path(id: other_account.id)
        expect(response).to redirect_to(accounts_path)
      end

      it "sets an alert flash message" do
        get account_path(id: other_account.id)
        expect(flash[:alert]).to eq(I18n.t("accounts.errors.not_found"))
      end
    end

    context "with non-existent account id" do
      it "redirects to accounts index" do
        get account_path(id: "non-existent-id")
        expect(response).to redirect_to(accounts_path)
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in page" do
        get account_path(id: account.id)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET #new" do
    it "returns a successful response" do
      get new_account_path
      expect(response).to have_http_status(:success)
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in page" do
        get new_account_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET #edit" do
    it "returns a successful response" do
      get edit_account_path(id: account.id)
      expect(response).to have_http_status(:success)
    end

    it "displays account information" do
      get edit_account_path(id: account.id)
      expect(response.body).to include(account.name)
    end

    context "with account from another user" do
      let(:other_user) { create(:user) }
      let(:other_account) { create(:account, user: other_user, name: "Other Account") }

      it "redirects to accounts index" do
        get edit_account_path(id: other_account.id)
        expect(response).to redirect_to(accounts_path)
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in page" do
        get edit_account_path(id: account.id)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST #create" do
    let(:valid_attributes) do
      {
        account_name: "New Account",
        current_balance: 500.00,
        saving_goal: 2000.00
      }
    end

    let(:invalid_attributes) do
      {
        account_name: "",
        current_balance: 100.00,
        saving_goal: 0.00
      }
    end

    context "with valid parameters" do
      it "creates a new account" do
        expect {
          post accounts_path, params: { account: valid_attributes }
        }.to change(Account, :count).by(1)
      end

      it "redirects to the account show page" do
        post accounts_path, params: { account: valid_attributes }
        created_account = Account.find_by(name: "New Account", user: user)
        expect(response).to redirect_to(account_path(id: created_account.id))
      end

      it "sets a success notice" do
        post accounts_path, params: { account: valid_attributes }
        expect(flash[:notice]).to eq(I18n.t("accounts.create.success"))
      end

      it "sets the correct saving goal" do
        post accounts_path, params: { account: valid_attributes }
        created_account = Account.find_by(name: "New Account", user: user)
        expect(created_account.saving_goal).to eq(2000.00)
      end

      it "adjusts the balance if different from zero" do
        post accounts_path, params: { account: valid_attributes }
        created_account = Account.find_by(name: "New Account", user: user)
        expect(created_account.balance).to eq(500.00)
      end

      it "creates a balance adjustment transaction" do
        expect {
          post accounts_path, params: { account: valid_attributes }
        }.to change(Transaction, :count).by(1)
      end

      context "when account already exists" do
        let!(:existing_account) { create(:account, user: user, name: "Existing Account", balance: 1000.0) }

        it "does not create a new account" do
          expect {
            post accounts_path, params: { account: valid_attributes.merge(account_name: "Existing Account") }
          }.not_to change(Account, :count)
        end

        it "updates the saving goal" do
          post accounts_path, params: { account: valid_attributes.merge(account_name: "Existing Account", current_balance: 1500.00) }
          expect(existing_account.reload.saving_goal).to eq(2000.00)
        end
      end
    end

    context "with invalid parameters" do
      it "does not create an account" do
        expect {
          post accounts_path, params: { account: invalid_attributes }
        }.not_to change(Account, :count)
      end

      it "returns unprocessable entity status" do
        post accounts_path, params: { account: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in page" do
        post accounts_path, params: { account: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end

      it "does not create an account" do
        sign_out user
        expect {
          post accounts_path, params: { account: valid_attributes }
        }.not_to change(Account, :count)
      end
    end
  end

  describe "PATCH #update" do
    let(:valid_update_attributes) do
      {
        account_name: "Updated Savings",
        current_balance: 1500.00,
        saving_goal: 6000.00
      }
    end

    let(:invalid_update_attributes) do
      {
        account_name: "",
        current_balance: 100.00,
        saving_goal: 0.00
      }
    end

    context "with valid parameters" do
      it "updates the account" do
        patch account_path(id: account.id), params: { account: valid_update_attributes }
        expect(account.reload.name).to eq("Updated Savings")
        expect(account.reload.saving_goal).to eq(6000.00)
      end

      it "redirects to the account show page" do
        patch account_path(id: account.id), params: { account: valid_update_attributes }
        expect(response).to redirect_to(account_path(id: account.id))
      end

      it "sets a success notice" do
        patch account_path(id: account.id), params: { account: valid_update_attributes }
        expect(flash[:notice]).to eq(I18n.t("accounts.update.success"))
      end

      it "adjusts balance if needed" do
        patch account_path(id: account.id), params: { account: valid_update_attributes }
        expect(account.reload.balance).to eq(1500.00)
      end
    end

    context "with invalid parameters" do
      it "does not update the account" do
        original_name = account.name
        patch account_path(id: account.id), params: { account: invalid_update_attributes }
        expect(account.reload.name).to eq(original_name)
      end

      it "returns unprocessable entity status" do
        patch account_path(id: account.id), params: { account: invalid_update_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with account from another user" do
      let(:other_user) { create(:user) }
      let(:other_account) { create(:account, user: other_user, name: "Other Account") }

      it "redirects to accounts index" do
        patch account_path(id: other_account.id), params: { account: valid_update_attributes }
        expect(response).to redirect_to(accounts_path)
      end

      it "does not update the account" do
        original_name = other_account.name
        patch account_path(id: other_account.id), params: { account: valid_update_attributes }
        expect(other_account.reload.name).to eq(original_name)
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in page" do
        patch account_path(id: account.id), params: { account: valid_update_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "DELETE #destroy" do
    context "when account has no transactions" do
      it "deletes the account" do
        account_to_delete = create(:account, user: user, name: "To Delete")
        expect {
          delete account_path(id: account_to_delete.id)
        }.to change(Account, :count).by(-1)
      end

      it "redirects to accounts index" do
        delete account_path(id: account.id)
        expect(response).to redirect_to(accounts_path)
      end

      it "sets a success notice" do
        delete account_path(id: account.id)
        expect(flash[:notice]).to eq(I18n.t("accounts.destroy.success"))
      end
    end

    context "when account has transactions" do
      before do
        transaction_type = create(:transaction_type, user: user)
        create(:transaction, account: account, user: user, transaction_type: transaction_type)
      end

      it "does not delete the account" do
        expect {
          delete account_path(id: account.id)
        }.not_to change(Account, :count)
      end

      it "redirects to the account show page" do
        delete account_path(id: account.id)
        expect(response).to redirect_to(account_path(id: account.id))
      end

      it "sets an alert flash message" do
        delete account_path(id: account.id)
        expect(flash[:alert]).to eq(I18n.t("accounts.destroy.has_transactions"))
      end
    end

    context "with account from another user" do
      let(:other_user) { create(:user) }
      let(:other_account) { create(:account, user: other_user, name: "Other Account") }

      it "redirects to accounts index" do
        delete account_path(id: other_account.id)
        expect(response).to redirect_to(accounts_path)
      end

      it "does not delete the account" do
        other_account # create it
        expect {
          delete account_path(id: other_account.id)
        }.not_to change(Account, :count)
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in page" do
        delete account_path(id: account.id)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
