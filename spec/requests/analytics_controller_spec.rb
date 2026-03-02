# frozen_string_literal: true

require "rails_helper"

RSpec.describe AnalyticsController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }

  before do
    sign_in user, scope: :user
  end

  describe "GET #index" do
    it "returns a successful response" do
      get analytics_path
      expect(response).to have_http_status(:success)
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in page" do
        get analytics_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    it "defaults to this_month period" do
      get analytics_path
      expect(assigns(:period)).to eq("this_month")
    end

    context "with period parameter" do
      it "accepts today period" do
        get analytics_path(period: "today")
        expect(assigns(:period)).to eq("today")
      end

      it "accepts yesterday period" do
        get analytics_path(period: "yesterday")
        expect(assigns(:period)).to eq("yesterday")
      end

      it "accepts this_week period" do
        get analytics_path(period: "this_week")
        expect(assigns(:period)).to eq("this_week")
      end

      it "accepts this_month period" do
        get analytics_path(period: "this_month")
        expect(assigns(:period)).to eq("this_month")
      end

      it "accepts last_3_months period" do
        get analytics_path(period: "last_3_months")
        expect(assigns(:period)).to eq("last_3_months")
      end

      it "accepts last_6_months period" do
        get analytics_path(period: "last_6_months")
        expect(assigns(:period)).to eq("last_6_months")
      end

      it "accepts last_12_months period" do
        get analytics_path(period: "last_12_months")
        expect(assigns(:period)).to eq("last_12_months")
      end

      it "accepts all_time period" do
        get analytics_path(period: "all_time")
        expect(assigns(:period)).to eq("all_time")
      end

      it "accepts custom period with date range" do
        get analytics_path(period: "custom", start_date: "2025-01-01", end_date: "2025-06-30")
        expect(assigns(:period)).to eq("custom")
      end

      it "ignores invalid period and defaults to this_month" do
        get analytics_path(period: "invalid")
        expect(assigns(:period)).to eq("this_month")
      end
    end

    # ─── Income / Expense section ─────────────────────────────────────

    describe "income/expense data" do
      let(:account) { create(:account, user: user, name: "Main") }
      let(:income_type) { create(:transaction_type, user: user, kind: "income", name: "Salary") }
      let(:expense_type) { create(:transaction_type, user: user, kind: "expense", name: "Food") }

      before do
        create(:transaction, user: user, account: account, transaction_type: income_type,
               amount: 500.0, transaction_date: Date.current, description: "Salary")
        create(:transaction, user: user, account: account, transaction_type: expense_type,
               amount: -200.0, transaction_date: Date.current, description: "Food")
      end

      it "calculates total income" do
        get analytics_path
        expect(assigns(:total_income)).to eq(500.0)
      end

      it "calculates total expenses" do
        get analytics_path
        expect(assigns(:total_expenses)).to eq(200.0)
      end

      it "calculates net" do
        get analytics_path
        expect(assigns(:net)).to eq(300.0)
      end

      it "groups income by category" do
        get analytics_path
        expect(assigns(:income_by_category)).to include("Salary" => 500.0)
      end

      it "groups expense by category" do
        get analytics_path
        expect(assigns(:expense_by_category)).to include("Food" => 200.0)
      end

      it "provides top spending data" do
        get analytics_path
        expect(assigns(:top_spending)).to include("Food" => 200.0)
      end

      it "includes debt_in repayments as income" do
        debt_in_type = create(:transaction_type, user: user, kind: "debt_in", name: "Loan Repayment Received")
        create(:transaction, user: user, account: account, transaction_type: debt_in_type,
               amount: 300.0, transaction_date: Date.current, description: "Repayment from Alice")

        get analytics_path
        expect(assigns(:total_income)).to eq(800.0) # 500 salary + 300 debt_in
        expect(assigns(:income_by_category)).to include("Loan Repayment Received" => 300.0)
      end

      it "includes debt_out repayments as expense" do
        debt_out_type = create(:transaction_type, user: user, kind: "debt_out", name: "Loan Given")
        create(:transaction, user: user, account: account, transaction_type: debt_out_type,
               amount: -150.0, transaction_date: Date.current, description: "Repayment to Bob")

        get analytics_path
        expect(assigns(:total_expenses)).to eq(350.0) # 200 food + 150 debt_out
        expect(assigns(:top_spending)).to include("Loan Given" => 150.0)
      end

      context "with no transactions" do
        before { Transaction.destroy_all }

        it "returns zero totals" do
          get analytics_path
          expect(assigns(:total_income)).to eq(0)
          expect(assigns(:total_expenses)).to eq(0)
          expect(assigns(:net)).to eq(0)
        end
      end
    end

    # ─── Debts section ───────────────────────────────────────────────

    describe "debts data" do
      before do
        create(:debt, user: user, name: "Alice", direction: "lent", total_lent: 1000.0, total_reimbursed: 200.0, status: "ongoing")
        create(:debt, user: user, name: "Bob", direction: "borrowed", total_lent: 500.0, total_reimbursed: 100.0, status: "ongoing")
        create(:debt, user: user, name: "Carol", direction: "lent", total_lent: 300.0, total_reimbursed: 300.0, status: "paid")
      end

      it "calculates total owed to me" do
        get analytics_path
        expect(assigns(:total_owed_to_me)).to eq(800.0)
      end

      it "calculates total I owe" do
        get analytics_path
        expect(assigns(:total_i_owe)).to eq(400.0)
      end

      it "counts ongoing debts" do
        get analytics_path
        expect(assigns(:total_debts_count)).to eq(2)
      end

      it "counts paid debts" do
        get analytics_path
        expect(assigns(:paid_debts_count)).to eq(1)
      end

      it "groups owed to me by person" do
        get analytics_path
        expect(assigns(:owed_to_me_by_person)).to include("Alice" => 800.0)
      end

      it "groups what I owe by person" do
        get analytics_path
        expect(assigns(:i_owe_by_person)).to include("Bob" => 400.0)
      end

      context "with no debts" do
        before { Debt.destroy_all }

        it "returns zero totals" do
          get analytics_path
          expect(assigns(:total_owed_to_me)).to eq(0)
          expect(assigns(:total_i_owe)).to eq(0)
        end
      end
    end

    # ─── Savings section ─────────────────────────────────────────────

    describe "savings data" do
      before do
        create(:account, user: user, name: "Savings", balance: 2000.0, saving_goal: 5000.0)
        create(:account, user: user, name: "Checking", balance: 1000.0, saving_goal: 0.0)
        create(:account, user: user, name: "Emergency", balance: 500.0, saving_goal: 1000.0)
      end

      it "calculates total balance" do
        get analytics_path
        expect(assigns(:total_balance)).to eq(3500.0)
      end

      it "calculates total saving goal" do
        get analytics_path
        expect(assigns(:total_saving_goal)).to eq(6000.0)
      end

      it "calculates total saved toward goals" do
        get analytics_path
        expect(assigns(:total_saved)).to eq(2500.0)
      end

      it "provides account balance distribution" do
        get analytics_path
        balances = assigns(:account_balances)
        expect(balances).to include("Savings" => 2000.0)
        expect(balances).to include("Checking" => 1000.0)
        expect(balances).to include("Emergency" => 500.0)
      end

      it "provides goals progress" do
        get analytics_path
        progress = assigns(:goals_progress)
        expect(progress.length).to eq(2) # Only accounts with saving goals

        savings_goal = progress.find { |g| g[:name] == "Savings" }
        expect(savings_goal[:progress]).to eq(40)

        emergency_goal = progress.find { |g| g[:name] == "Emergency" }
        expect(emergency_goal[:progress]).to eq(50)
      end

      context "with no accounts" do
        before { Account.destroy_all }

        it "returns zero totals" do
          get analytics_path
          expect(assigns(:total_balance)).to eq(0)
          expect(assigns(:total_saving_goal)).to eq(0)
        end
      end
    end

    # ─── Period filtering ────────────────────────────────────────────

    describe "period filtering" do
      let(:account) { create(:account, user: user, name: "Main") }
      let(:income_type) { create(:transaction_type, user: user, kind: "income", name: "Salary") }

      it "filters by today" do
        create(:transaction, user: user, account: account, transaction_type: income_type,
               amount: 100.0, transaction_date: Date.current, description: "Today")
        create(:transaction, user: user, account: account, transaction_type: income_type,
               amount: 200.0, transaction_date: 1.day.ago.to_date, description: "Yesterday")

        get analytics_path(period: "today")
        expect(assigns(:total_income)).to eq(100.0)
      end

      it "filters by yesterday" do
        create(:transaction, user: user, account: account, transaction_type: income_type,
               amount: 100.0, transaction_date: 1.day.ago.to_date, description: "Yesterday")
        create(:transaction, user: user, account: account, transaction_type: income_type,
               amount: 200.0, transaction_date: 3.days.ago.to_date, description: "Older")

        get analytics_path(period: "yesterday")
        expect(assigns(:total_income)).to eq(100.0)
      end

      it "filters by this_month" do
        create(:transaction, user: user, account: account, transaction_type: income_type,
               amount: 100.0, transaction_date: Date.current, description: "Current")
        create(:transaction, user: user, account: account, transaction_type: income_type,
               amount: 200.0, transaction_date: 2.months.ago.to_date, description: "Old")

        get analytics_path(period: "this_month")
        expect(assigns(:total_income)).to eq(100.0)
      end

      it "filters by last_3_months" do
        create(:transaction, user: user, account: account, transaction_type: income_type,
               amount: 100.0, transaction_date: 1.month.ago.to_date, description: "Recent")
        create(:transaction, user: user, account: account, transaction_type: income_type,
               amount: 200.0, transaction_date: 6.months.ago.to_date, description: "Old")

        get analytics_path(period: "last_3_months")
        expect(assigns(:total_income)).to eq(100.0)
      end

      it "filters by last_12_months" do
        create(:transaction, user: user, account: account, transaction_type: income_type,
               amount: 100.0, transaction_date: 6.months.ago.to_date, description: "Recent")
        create(:transaction, user: user, account: account, transaction_type: income_type,
               amount: 200.0, transaction_date: 2.years.ago.to_date, description: "Old")

        get analytics_path(period: "last_12_months")
        expect(assigns(:total_income)).to eq(100.0)
      end

      it "filters by custom date range" do
        create(:transaction, user: user, account: account, transaction_type: income_type,
               amount: 100.0, transaction_date: Date.new(2025, 3, 15), description: "In Range")
        create(:transaction, user: user, account: account, transaction_type: income_type,
               amount: 200.0, transaction_date: Date.new(2025, 1, 1), description: "Out of Range")

        get analytics_path(period: "custom", start_date: "2025-03-01", end_date: "2025-03-31")
        expect(assigns(:total_income)).to eq(100.0)
      end

      it "shows all transactions for all_time" do
        create(:transaction, user: user, account: account, transaction_type: income_type,
               amount: 100.0, transaction_date: Date.current, description: "Current")
        create(:transaction, user: user, account: account, transaction_type: income_type,
               amount: 200.0, transaction_date: 2.years.ago.to_date, description: "Old")

        get analytics_path(period: "all_time")
        expect(assigns(:total_income)).to eq(300.0)
      end
    end
  end
end
