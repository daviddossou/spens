# frozen_string_literal: true

require "rails_helper"

RSpec.describe BudgetEntriesController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  before { sign_in user, scope: :user }

  describe "PATCH #update" do
    it "overrides the month's planned amount without touching the rule" do
      entry = create(:budget_entry, space: space, planned_amount: 25_000)
      patch budget_entry_path(id: entry.id), params: { budget_entry: { planned_amount: 30_000 } }

      expect(entry.reload.planned_amount).to eq(30_000)
      expect(entry.budget_item.amount).to eq(25_000)
      expect(response).to have_http_status(:see_other)
    end

    it "rejects an invalid amount" do
      entry = create(:budget_entry, space: space)
      patch budget_entry_path(id: entry.id), params: { budget_entry: { planned_amount: 0 } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
