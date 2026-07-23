# frozen_string_literal: true

require "rails_helper"

RSpec.describe BudgetsController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:month) { Date.current.beginning_of_month }

  before { sign_in user, scope: :user }

  describe "GET #index" do
    it "shows the empty state when no items exist" do
      get budgets_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t("budgets.index.empty_title"))
    end

    it "materializes and shows the month's entries with totals" do
      type = create(:transaction_type, space: space, kind: "expense", name: "🏠 Rent")
      create(:budget_item, space: space, transaction_type: type, amount: 250_000, starts_on: month)

      get budgets_path
      expect(response.body).to include("Rent")
      expect(space.budget_entries.for_month(month).count).to eq(1)
    end

    it "navigates to another month via the month param" do
      get budgets_path(month: (month >> 1).strftime("%Y-%m"))
      expect(response).to have_http_status(:success)
    end

    it "falls back to the current month on a malformed month param" do
      get budgets_path(month: "not-a-month")
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #summary" do
    it "renders the read-only variance view" do
      create(:budget_item, space: space, starts_on: month << 1)
      get summary_budgets_path(month: (month << 1).strftime("%Y-%m"))
      expect(response).to have_http_status(:success)
    end
  end
end
