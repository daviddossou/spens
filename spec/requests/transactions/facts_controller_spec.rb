# frozen_string_literal: true

require "rails_helper"

RSpec.describe Transactions::FactsController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:account) { create(:account, space: space, name: "Bank") }
  # A custom (non-taxonomy) category name, so edits don't re-resolve it to a node.
  let(:type) { create(:transaction_type, space: space, kind: "expense", name: "Bricolage maison") }
  let(:transaction) do
    create(:transaction, space: space, user: user, account: account,
                         transaction_type: type, amount: -2000)
  end

  before { sign_in user, scope: :user }

  describe "GET #edit" do
    it "opens the one-field sheet for each fact" do
      %w[category account date].each do |fact|
        get fact_transaction_path(id: transaction.id, fact: fact)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("modal")
      end
    end

    it "rejects an unknown fact at the routing layer" do
      expect do
        get fact_transaction_path(id: transaction.id, fact: "amount")
      end.to raise_error(ActionController::UrlGenerationError)
    end
  end

  describe "one-field PATCH through transactions#update" do
    it "changes only the date, keeping everything else" do
      patch transaction_path(id: transaction.id),
            params: { transaction: { transaction_date: "2026-08-01" } }
      expect(response).to have_http_status(:see_other)

      transaction.reload
      expect(transaction.transaction_date).to eq(Date.new(2026, 8, 1))
      expect(transaction.transaction_type).to eq(type)
      expect(transaction.account).to eq(account)
      expect(transaction.amount).to eq(-2000)
    end

    it "changes only the account, adjusting balances through the ledger" do
      # The factory posts the ledger on create, so Bank already carries the
      # -2000 expense; moving it hands the weight to Wallet and clears Bank.
      other = create(:account, space: space, name: "Wallet", balance: 10_000)
      transaction # materialize: the factory posts the ledger effect on create
      expect(account.reload.balance).to eq(-2_000)

      patch transaction_path(id: transaction.id),
            params: { transaction: { account_name: other.name } }
      expect(response).to have_http_status(:see_other)

      expect(transaction.reload.account).to eq(other)
      expect(other.reload.balance).to eq(8_000) # the expense now weighs on Wallet
      expect(account.reload.balance).to eq(0)   # and was reversed off Bank
    end
  end
end
