# frozen_string_literal: true

require "rails_helper"

RSpec.describe Budgets::CategoriesController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:month) { Date.current.beginning_of_month }
  let(:account) { create(:account, space: space, name: "Trade Republic") }
  let(:groceries) { create(:transaction_type, space: space, kind: "expense", name: "🛒 Provisions") }
  let(:frozen) { create(:transaction_type, space: space, kind: "expense", name: "🧊 Surgelés", parent: groceries) }

  before do
    travel_to Time.zone.local(2026, 9, 13, 12)
    sign_in user, scope: :user
  end

  def record(type, amount, date: month + 5, **attrs)
    create(:transaction, space: space, transaction_type: type, account: account, amount: amount,
                         transaction_date: date, **attrs)
  end

  def show(type = groceries, month_value = month, **params)
    get category_budgets_path(id: type.id, month: month_value.strftime("%Y-%m"), **params)
  end

  describe "the list adds up to the budgeted amount" do
    before do
      create(:budget_item, space: space, transaction_type: groceries, amount: 500, starts_on: month)
      record(groceries, -300, label: "Carrefour")
      record(frozen, -75.5, label: "Picard")
      record(groceries, -1_000, date: month << 1) # previous month
    end

    it "lists the month's movements on the category and its children, fees excluded" do
      parent = record(groceries, -20, label: "Retrait")
      record(groceries, -1.5, fee_parent_id: parent.id)

      show
      expect(response).to have_http_status(:success)
      expect(assigns(:total)).to eq(395.5)
      expect(assigns(:transactions).size).to eq(3)
      expect(response.body).to include("Carrefour").and include("Picard").and include("Surgelés")
    end

    it "overlays the budget line on the header with the row's own status" do
      show
      expect(assigns(:progress)).to be_present
      expect(response.body).to include(I18n.t("budgets.row.in_progress"))
      expect(response.body).to include(I18n.t("budgets.categories.show.adjust_envelope"))
    end

    it "says when the line is over" do
      record(groceries, -200)
      show
      expect(response.body).to include(I18n.t("budgets.row.done_expense"))
      expect(response.body).to include("budget-category__amount--over")
    end

    it "offers no envelope action on a closed month" do
      show(groceries, month << 1)
      expect(response.body).not_to include(I18n.t("budgets.categories.show.adjust_envelope"))
      expect(response.body).not_to include(I18n.t("budgets.categories.show.create_envelope"))
    end

    it "states the missing sub-category on a parent with children" do
      show
      expect(response.body).to include(I18n.t("budgets.categories.show.no_subcategory"))
    end

    it "does not repeat the page's own category in the row subtitle" do
      show(frozen)
      expect(response.body).not_to include(I18n.t("budgets.categories.show.no_subcategory"))
      expect(response.body).not_to include("Surgelés · Trade Republic")
      expect(response.body).to include("Trade Republic")
    end
  end

  describe "without a budget line" do
    it "shows the month's amount and offers to create an envelope" do
      record(groceries, -40)
      show
      expect(assigns(:progress)).to be_nil
      expect(response.body).to include(I18n.t("budgets.categories.show.create_envelope"))
      expect(response.body).not_to include(I18n.t("budgets.categories.show.adjust_envelope"))
    end

    it "shows the empty state with an add action when nothing moved" do
      show
      expect(response.body).to include(I18n.t("budgets.categories.show.empty_title"))
      expect(response.body).to include(I18n.t("budgets.categories.show.add_expense"))
    end

    it "names the usual day when a regular charge lands at the same date each month" do
      create(:budget_item, space: space, transaction_type: groceries, amount: 500, starts_on: month << 3)
      record(groceries, -31, date: (month << 1) + 24)
      record(groceries, -31, date: (month << 2) + 25)
      record(groceries, -31, date: (month << 3) + 24)
      show
      expect(assigns(:usual_day)).to eq(25)
      expect(response.body).to include(I18n.t("budgets.categories.show.usual_day_expense", day: 25))
    end

    it "stays silent on the day when the history is irregular" do
      create(:budget_item, space: space, transaction_type: groceries, amount: 500, starts_on: month << 3)
      record(groceries, -31, date: (month << 1) + 3)
      record(groceries, -31, date: (month << 2) + 25)
      record(groceries, -31, date: (month << 3) + 14)
      show
      expect(assigns(:usual_day)).to be_nil
    end

    it "averages the three previous months" do
      record(groceries, -300, date: month << 1)
      record(groceries, -600, date: month << 2)
      show
      expect(assigns(:average)).to eq(300)
    end
  end

  describe "a parent whose child has its own line" do
    before do
      create(:budget_item, space: space, transaction_type: frozen, amount: 100, starts_on: month)
      record(groceries, -3.1, label: "Baguette")
      record(frozen, -75.5, label: "Picard")
    end

    it "counts only what the Budget page counts for it and hands the child over" do
      show
      expect(assigns(:total)).to eq(3.1)
      expect(assigns(:transactions).size).to eq(1)
      expect(response.body).not_to include("Picard")
      expect(response.body).to include(I18n.t("budgets.categories.show.child_own_line_html", child: "<strong>🧊 Surgelés</strong>"))
      expect(response.body).to include(category_budgets_path(id: frozen.id, month: month.strftime("%Y-%m")))
      expect(response.body).to include(I18n.t("budgets.categories.show.subtitle_children_budgeted", count: 1))
      expect(response.body).not_to include(I18n.t("budgets.categories.show.subtitle_unbudgeted"))
    end

    it "keeps the whole subtree once the parent has a line of its own" do
      create(:budget_item, space: space, transaction_type: groceries, amount: 500, starts_on: month)
      show
      expect(assigns(:total)).to eq(78.6)
      expect(assigns(:child_progresses)).to be_empty
    end
  end

  describe "a child under a budgeted parent" do
    it "links up to the parent's line instead of carrying a bar" do
      create(:budget_item, space: space, transaction_type: groceries, amount: 500, starts_on: month)
      record(frozen, -75.5)

      show(frozen)
      expect(assigns(:entry)).to be_nil
      expect(assigns(:parent_entry)).to be_present
      expect(response.body).to include("Provisions")
      expect(response.body).not_to include("role=\"progressbar\"")
      expect(response.body).not_to include(I18n.t("budgets.categories.show.create_envelope"))
    end
  end

  it "rejects non-category kinds" do
    transfer = create(:transaction_type, space: space, kind: "transfer_out", name: "Out")
    show(transfer)
    expect(response).to have_http_status(:not_found)
  end

  describe "entry points" do
    it "links each category line of the Budget page to its detail in live and Bilan modes" do
      create(:budget_item, space: space, transaction_type: groceries, amount: 500, starts_on: month)
      detail = category_budgets_path(id: groceries.id, month: month.strftime("%Y-%m"))

      get budgets_path(month: month.strftime("%Y-%m"))
      expect(response.body).to include(detail)

      get budgets_path(month: month.strftime("%Y-%m"), view: "wrap_up")
      expect(response.body).to include(detail)

      get budgets_path(month: month.strftime("%Y-%m"), view: "plan")
      expect(response.body).not_to include(detail)
    end
  end
end
