# frozen_string_literal: true

require "rails_helper"

RSpec.describe BudgetItemsController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:month) { Date.current.beginning_of_month }

  before { sign_in user, scope: :user }

  describe "POST #create" do
    it "creates the item and redirects to the month's budget" do
      post budget_items_path, params: { budget_item: {
        kind: "expense", transaction_type_name: "Rent", amount: 250_000,
        frequency: "monthly", starts_on: month
      } }

      expect(response).to have_http_status(:see_other)
      expect(response.location).to include("/budgets?month=#{month.strftime('%Y-%m')}")
      expect(space.budget_items.active.count).to eq(1)
    end

    it "re-renders on validation failure" do
      post budget_items_path, params: { budget_item: { kind: "expense", transaction_type_name: "", amount: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH #update" do
    it "updates the rule" do
      item = create(:budget_item, space: space, amount: 10_000)
      patch budget_item_path(id: item.id), params: { budget_item: { amount: 12_000 } }

      expect(item.reload.amount).to eq(12_000)
      expect(response).to have_http_status(:see_other)
    end
  end

  describe "DELETE #destroy" do
    it "deactivates the item and removes current/future pending entries" do
      item = create(:budget_item, space: space, starts_on: month)
      Budgets::EnsureEntriesService.new(space: space, month: month).call

      delete budget_item_path(id: item.id)

      expect(item.reload.active).to be false
      expect(space.budget_entries.for_month(month)).to be_empty
    end

    it "does not touch another space's items" do
      other_item = create(:budget_item)
      delete budget_item_path(id: other_item.id)
      expect(other_item.reload.active).to be true
      expect(response).to redirect_to(budgets_path)
    end
  end
end
