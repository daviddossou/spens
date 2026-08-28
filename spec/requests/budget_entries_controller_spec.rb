# frozen_string_literal: true

require "rails_helper"

RSpec.describe BudgetEntriesController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  before { sign_in user, scope: :user }

  describe "PATCH #update" do
    it "overrides just this month (flagged) without touching the rule" do
      entry = create(:budget_entry, space: space, planned_amount: 25_000)
      patch budget_entry_path(id: entry.id), params: { amount: 30_000 }

      entry.reload
      expect(entry.planned_amount).to eq(30_000)
      expect(entry).to be_overridden
      expect(entry.overridden_at).to be_present
      expect(entry.budget_item.amount).to eq(25_000) # rule untouched
      expect(response).to have_http_status(:see_other)
    end

    it "does not flag an override that matches the rule" do
      entry = create(:budget_entry, space: space, planned_amount: 25_000)
      patch budget_entry_path(id: entry.id), params: { amount: 25_000 }
      expect(entry.reload).not_to be_overridden
    end

    it "rejects an invalid amount" do
      entry = create(:budget_entry, space: space)
      patch budget_entry_path(id: entry.id), params: { amount: 0 }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "edits the rule from this month when scope is rule" do
      entry = create(:budget_entry, space: space, planned_amount: 25_000)
      patch budget_entry_path(id: entry.id), params: { scope: "rule", amount: 40_000 }

      expect(entry.budget_item.reload.amount).to eq(40_000)
      expect(response).to have_http_status(:see_other)
    end
  end

  describe "POST #revert" do
    it "drops the exception and restores the rule amount" do
      entry = create(:budget_entry, space: space, planned_amount: 30_000, overridden: true, overridden_at: Time.current)
      post revert_budget_entry_path(id: entry.id)

      entry.reload
      expect(entry).not_to be_overridden
      expect(entry.planned_amount).to eq(entry.budget_item.amount)
      expect(response).to have_http_status(:see_other)
    end
  end
end
