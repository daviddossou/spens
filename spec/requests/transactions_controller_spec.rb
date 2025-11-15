# frozen_string_literal: true

require "rails_helper"

RSpec.describe TransactionsController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }

  before do
    sign_in user, scope: :user
  end

  describe "GET #new" do
    context "when requesting HTML format" do
      it "returns a successful response" do
        get new_transaction_path
        expect(response).to have_http_status(:success)
      end

      it "accepts kind parameter" do
        get new_transaction_path(kind: 'income')
        expect(response).to have_http_status(:success)
      end

      it "accepts account_id parameter" do
        account = create(:account, user: user, name: "Savings Account")
        get new_transaction_path(account_id: account.id)
        expect(response).to have_http_status(:success)
      end
    end

    context "when requesting turbo_stream format" do
      it "returns a successful response" do
        get new_transaction_path(kind: 'income'), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('turbo-stream')
      end

      it "renders the form partial" do
        get new_transaction_path(kind: 'income'), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
        expect(response.body).to include('turbo-stream')
        expect(response.body).to include('transaction_form')
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in page" do
        get new_transaction_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST #create" do
    let(:valid_attributes) do
      {
        kind: 'expense',
        account_name: 'Cash',
        transaction_type_name: 'Groceries',
        amount: 100.50,
        transaction_date: Date.current,
        note: 'Weekly shopping'
      }
    end

    let(:invalid_attributes) do
      {
        kind: 'expense',
        account_name: '',
        transaction_type_name: 'Groceries',
        amount: -10,
        transaction_date: Date.current
      }
    end

    context "with valid parameters" do
      it "creates a new transaction" do
        expect {
          post transactions_path, params: { transaction: valid_attributes }
        }.to change(Transaction, :count).by(1)
      end

      it "redirects to new transaction path" do
        post transactions_path, params: { transaction: valid_attributes }
        expect(response).to redirect_to(new_transaction_path)
      end

      it "sets a success notice" do
        post transactions_path, params: { transaction: valid_attributes }
        expect(flash[:notice]).to eq(I18n.t('transactions.create.success'))
      end

      context "with transfer kind" do
        let(:transfer_attributes) do
          {
            kind: 'transfer',
            from_account_name: 'Bank',
            to_account_name: 'Cash',
            amount: 200.00,
            transaction_date: Date.current
          }
        end

        it "creates two transactions" do
          expect {
            post transactions_path, params: { transaction: transfer_attributes }
          }.to change(Transaction, :count).by(2)
        end

        it "redirects with success notice" do
          post transactions_path, params: { transaction: transfer_attributes }
          expect(response).to redirect_to(new_transaction_path)
          expect(flash[:notice]).to be_present
        end
      end

      context "with optional fields" do
        let(:attributes_with_date) do
          valid_attributes.merge(transaction_date: 1.week.ago.to_date)
        end

        it "accepts custom transaction date" do
          post transactions_path, params: { transaction: attributes_with_date }
          expect(response).to redirect_to(new_transaction_path)
        end

        it "accepts note field" do
          post transactions_path, params: { transaction: valid_attributes.merge(note: 'Test note') }
          expect(response).to redirect_to(new_transaction_path)
        end
      end
    end

    context "with invalid parameters" do
      it "does not create a transaction" do
        expect {
          post transactions_path, params: { transaction: invalid_attributes }
        }.not_to change(Transaction, :count)
      end

      it "returns unprocessable entity status" do
        post transactions_path, params: { transaction: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      context "missing required fields" do
        it "fails without amount" do
          attributes = valid_attributes.dup
          attributes.delete(:amount)

          expect {
            post transactions_path, params: { transaction: attributes }
          }.not_to change(Transaction, :count)
        end

        it "fails without account_name for expense" do
          attributes = valid_attributes.merge(account_name: '')

          expect {
            post transactions_path, params: { transaction: attributes }
          }.not_to change(Transaction, :count)
        end

        it "fails without transaction_type_name for expense" do
          attributes = valid_attributes.merge(transaction_type_name: '')

          expect {
            post transactions_path, params: { transaction: attributes }
          }.not_to change(Transaction, :count)
        end
      end

      context "transfer validations" do
        it "fails without from_account_name" do
          attributes = {
            kind: 'transfer',
            to_account_name: 'Cash',
            amount: 100
          }

          expect {
            post transactions_path, params: { transaction: attributes }
          }.not_to change(Transaction, :count)
        end

        it "fails without to_account_name" do
          attributes = {
            kind: 'transfer',
            from_account_name: 'Bank',
            amount: 100
          }

          expect {
            post transactions_path, params: { transaction: attributes }
          }.not_to change(Transaction, :count)
        end

        it "fails with same from and to accounts" do
          attributes = {
            kind: 'transfer',
            from_account_name: 'Cash',
            to_account_name: 'Cash',
            amount: 100
          }

          expect {
            post transactions_path, params: { transaction: attributes }
          }.not_to change(Transaction, :count)
        end
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in page" do
        post transactions_path, params: { transaction: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end

      it "does not create a transaction" do
        sign_out user
        expect {
          post transactions_path, params: { transaction: valid_attributes }
        }.not_to change(Transaction, :count)
      end
    end
  end

  describe "parameter handling" do
    it "permits all required parameters" do
      params = {
        transaction: {
          kind: 'expense',
          account_name: 'Cash',
          from_account_name: 'Bank',
          to_account_name: 'Cash',
          amount: 100,
          transaction_date: Date.current,
          transaction_type_name: 'Food',
          note: 'Test note',
          unpermitted_param: 'should be filtered'
        }
      }

      post transactions_path, params: params
      expect(response).to have_http_status(:found)
    end
  end

  describe "edge cases" do
    let(:base_attributes) do
      {
        kind: 'expense',
        account_name: 'Test Account',
        transaction_type_name: 'Groceries',
        amount: 100.50,
        transaction_date: Date.current
      }
    end

    context "with very large amounts" do
      it "handles large decimal values" do
        attributes = base_attributes.merge(amount: 999_999_999.99)
        post transactions_path, params: { transaction: attributes }
        expect(response).to redirect_to(new_transaction_path)
        expect(flash[:notice]).to be_present
      end
    end

    context "with special characters in fields" do
      it "handles special characters in account names" do
        attributes = base_attributes.merge(account_name: "Spëçîål Àççöunt €$£")
        post transactions_path, params: { transaction: attributes }
        expect(response).to redirect_to(new_transaction_path)
        expect(flash[:notice]).to be_present
      end

      it "handles special characters in notes" do
        attributes = base_attributes.merge(note: "Emoji test 🎉💰📈 and symbols @#$%")
        post transactions_path, params: { transaction: attributes }
        expect(response).to redirect_to(new_transaction_path)
        expect(flash[:notice]).to be_present
      end
    end

    context "with future dates" do
      it "accepts future transaction dates" do
        attributes = base_attributes.merge(transaction_date: 1.week.from_now.to_date)
        post transactions_path, params: { transaction: attributes }
        expect(response).to redirect_to(new_transaction_path)
        expect(flash[:notice]).to be_present
      end
    end

    context "with decimal precision" do
      it "handles amounts with many decimal places" do
        attributes = base_attributes.merge(amount: 100.123456)
        post transactions_path, params: { transaction: attributes }
        expect(response).to redirect_to(new_transaction_path)
        expect(flash[:notice]).to be_present
      end
    end
  end
end
