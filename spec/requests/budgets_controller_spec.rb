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
      expect(response.body).to include(I18n.t("budgets.index.add_first_item"))
    end

    it "materializes and shows the month's entries with totals" do
      type = create(:transaction_type, space: space, kind: "expense", name: "🏠 Rent")
      create(:budget_item, space: space, transaction_type: type, amount: 250_000, starts_on: month)

      get budgets_path
      expect(response.body).to include("Rent")
      expect(space.budget_entries.for_month(month).count).to eq(1)
    end

    it "splits expenses into vital (essential) and confort (adjustable)" do
      income_type = create(:transaction_type, space: space, kind: "income", name: "💰 Salaire")
      rent = create(:transaction_type, space: space, kind: "expense", name: "🏠 Loyer")
      fun = create(:transaction_type, space: space, kind: "expense", name: "🎉 Sorties")
      create(:budget_item, space: space, kind: "income", transaction_type: income_type, amount: 150_000, starts_on: month)
      create(:budget_item, space: space, transaction_type: rent, amount: 100_000, essential: true, starts_on: month)
      create(:budget_item, space: space, transaction_type: fun, amount: 20_000, essential: false, starts_on: month)

      get budgets_path

      expect(response.body).to include(I18n.t("budgets.index.vital_confort_title"))
      # Vital counts only the essential 100 000; confort is the adjustable 20 000.
      expect(assigns(:planned_vital)).to eq(100_000)
      expect(assigns(:planned_confort)).to eq(20_000)
      expect(assigns(:planned_expense_total)).to eq(120_000)
    end

    it "hides the vital/confort card when no expenses are planned" do
      income_type = create(:transaction_type, space: space, kind: "income", name: "💰 Salaire")
      create(:budget_item, space: space, kind: "income", transaction_type: income_type, amount: 150_000, starts_on: month)

      get budgets_path
      expect(response.body).not_to include(I18n.t("budgets.index.vital_confort_title"))
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

  describe "mode as a viewpoint on the month" do
    it "defaults each month to its time-based mode" do
      get budgets_path(month: (month >> 1).strftime("%Y-%m"))
      expect(assigns(:mode)).to eq(:plan)
      get budgets_path(month: month.strftime("%Y-%m"))
      expect(assigns(:mode)).to eq(:live)
      get budgets_path(month: (month << 1).strftime("%Y-%m"))
      expect(assigns(:mode)).to eq(:wrap_up)
    end

    it "exposes only the readings that make sense for the month" do
      get budgets_path(month: (month >> 1).strftime("%Y-%m"))
      expect(assigns(:allowed_modes)).to eq([ :plan ])
      get budgets_path(month: month.strftime("%Y-%m"))
      expect(assigns(:allowed_modes)).to eq([ :plan, :live, :wrap_up ])
      get budgets_path(month: (month << 1).strftime("%Y-%m"))
      expect(assigns(:allowed_modes)).to eq([ :plan, :wrap_up ])
    end

    it "honors an allowed view override without changing the month" do
      get budgets_path(month: month.strftime("%Y-%m"), view: "plan")
      expect(assigns(:mode)).to eq(:plan)
      expect(assigns(:month)).to eq(month)
    end

    it "clamps a view the month can't offer back to its default" do
      get budgets_path(month: (month >> 1).strftime("%Y-%m"), view: "wrap_up")
      expect(assigns(:mode)).to eq(:plan)
    end
  end

  describe "GET #summary" do
    it "permanently redirects to the Budget page for that month (Bilan mode)" do
      get summary_budgets_path(month: (month << 1).strftime("%Y-%m"))
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to(budgets_path(month: (month << 1).strftime("%Y-%m")))
    end
  end
end
