# frozen_string_literal: true

require "rails_helper"

RSpec.describe HomeController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }

  before do
    sign_in user, scope: :user
  end

  describe "GET #dashboard" do
    it "returns a successful response" do
      get dashboard_path
      expect(response).to have_http_status(:success)
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign in page" do
        get dashboard_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe "analytics data" do
      context "total balance" do
        it "sums all account balances" do
          create(:account, user: user, name: "Checking", balance: 1000.0)
          create(:account, user: user, name: "Savings", balance: 2500.0)

          get dashboard_path
          expect(assigns(:total_balance)).to eq(3500.0)
        end

        it "returns 0 when user has no accounts" do
          get dashboard_path
          expect(assigns(:total_balance)).to eq(0)
        end

        it "handles negative balances" do
          create(:account, user: user, name: "Checking", balance: -500.0)
          create(:account, user: user, name: "Savings", balance: 1000.0)

          get dashboard_path
          expect(assigns(:total_balance)).to eq(500.0)
        end
      end

      context "saved this month" do
        let(:account) { create(:account, user: user, name: "Main") }
        let(:income_type) { create(:transaction_type, user: user, kind: "income", name: "Salary") }
        let(:expense_type) { create(:transaction_type, user: user, kind: "expense", name: "Food") }

        it "sums transaction amounts for the current month" do
          create(:transaction, user: user, account: account, transaction_type: income_type,
                 amount: 500.0, transaction_date: Date.current, description: "Salary")
          create(:transaction, user: user, account: account, transaction_type: expense_type,
                 amount: -200.0, transaction_date: Date.current, description: "Food")

          get dashboard_path
          expect(assigns(:saved_this_month)).to eq(300.0)
        end

        it "excludes transactions from other months" do
          create(:transaction, user: user, account: account, transaction_type: income_type,
                 amount: 500.0, transaction_date: Date.current, description: "Salary")
          create(:transaction, user: user, account: account, transaction_type: expense_type,
                 amount: -200.0, transaction_date: 2.months.ago, description: "Old food")

          get dashboard_path
          expect(assigns(:saved_this_month)).to eq(500.0)
        end

        it "returns 0 when user has no transactions this month" do
          get dashboard_path
          expect(assigns(:saved_this_month)).to eq(0)
        end
      end

      context "owed to me (lent debts)" do
        it "sums remaining balance of ongoing lent debts" do
          create(:debt, user: user, name: "Alice", direction: "lent",
                 status: "ongoing", total_lent: 1000.0, total_reimbursed: 300.0)
          create(:debt, user: user, name: "Bob", direction: "lent",
                 status: "ongoing", total_lent: 500.0, total_reimbursed: 0.0)

          get dashboard_path
          expect(assigns(:owed_to_me)).to eq(1200.0)
        end

        it "excludes paid debts" do
          create(:debt, user: user, name: "Alice", direction: "lent",
                 status: "ongoing", total_lent: 1000.0, total_reimbursed: 300.0)
          create(:debt, :paid, user: user, name: "Charlie", direction: "lent",
                 total_lent: 500.0, total_reimbursed: 500.0)

          get dashboard_path
          expect(assigns(:owed_to_me)).to eq(700.0)
        end

        it "excludes borrowed debts" do
          create(:debt, user: user, name: "Alice", direction: "lent",
                 status: "ongoing", total_lent: 1000.0, total_reimbursed: 0.0)
          create(:debt, :borrowed, user: user, name: "Bank", direction: "borrowed",
                 status: "ongoing", total_lent: 5000.0, total_reimbursed: 0.0)

          get dashboard_path
          expect(assigns(:owed_to_me)).to eq(1000.0)
        end

        it "returns 0 when user has no lent debts" do
          get dashboard_path
          expect(assigns(:owed_to_me)).to eq(0)
        end
      end

      context "I owe (borrowed debts)" do
        it "sums remaining balance of ongoing borrowed debts" do
          create(:debt, user: user, name: "Bank", direction: "borrowed",
                 status: "ongoing", total_lent: 5000.0, total_reimbursed: 1000.0)
          create(:debt, user: user, name: "Mom", direction: "borrowed",
                 status: "ongoing", total_lent: 2000.0, total_reimbursed: 500.0)

          get dashboard_path
          expect(assigns(:i_owe)).to eq(5500.0)
        end

        it "excludes paid debts" do
          create(:debt, user: user, name: "Bank", direction: "borrowed",
                 status: "ongoing", total_lent: 5000.0, total_reimbursed: 1000.0)
          create(:debt, :paid, user: user, name: "Friend", direction: "borrowed",
                 total_lent: 200.0, total_reimbursed: 200.0)

          get dashboard_path
          expect(assigns(:i_owe)).to eq(4000.0)
        end

        it "excludes lent debts" do
          create(:debt, user: user, name: "Bank", direction: "borrowed",
                 status: "ongoing", total_lent: 5000.0, total_reimbursed: 0.0)
          create(:debt, user: user, name: "Alice", direction: "lent",
                 status: "ongoing", total_lent: 1000.0, total_reimbursed: 0.0)

          get dashboard_path
          expect(assigns(:i_owe)).to eq(5000.0)
        end

        it "returns 0 when user has no borrowed debts" do
          get dashboard_path
          expect(assigns(:i_owe)).to eq(0)
        end
      end

      context "currency" do
        it "assigns the user currency" do
          get dashboard_path
          expect(assigns(:currency)).to eq(user.currency)
        end
      end
    end

    describe "stat cards rendering" do
      it "renders the stat cards section" do
        get dashboard_path
        expect(response.body).to include("stat-cards")
      end

      it "renders all four stat card labels" do
        get dashboard_path
        expect(response.body).to include(I18n.t("home.dashboard.stats.total_balance"))
        expect(response.body).to include(I18n.t("home.dashboard.stats.saved_this_month"))
        expect(response.body).to include(I18n.t("home.dashboard.stats.owed_to_me"))
        expect(response.body).to include(I18n.t("home.dashboard.stats.i_owe"))
      end

      it "does not render the old transactions title header" do
        get dashboard_path
        expect(response.body).not_to include("dashboard__header")
      end
    end

    describe "pagination" do
      it "defaults to page 1" do
        get dashboard_path
        expect(assigns(:page)).to eq(1)
      end

      it "accepts page parameter" do
        get dashboard_path, params: { page: 2 }
        expect(assigns(:page)).to eq(2)
      end

      context "with turbo_stream format on page > 1" do
        it "responds with turbo_stream" do
          get dashboard_path, params: { page: 2 },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
          expect(response.content_type).to include("turbo-stream")
        end
      end
    end
  end

  describe "GET #index" do
    context "when authenticated" do
      it "redirects to dashboard" do
        get root_path
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to sign up page" do
        get root_path
        expect(response).to redirect_to(new_user_registration_path)
      end
    end
  end
end
