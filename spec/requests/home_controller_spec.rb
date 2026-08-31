# frozen_string_literal: true

require "rails_helper"

RSpec.describe HomeController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  # Fixed mid-month noon: the controller reads dates in the user's time zone,
  # and a real month boundary would shift its "today" past the spec's.
  before do
    travel_to Time.zone.local(2026, 8, 18, 12)
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

        it "sums only reserved accounts into the set-aside total" do
          create(:account, user: user, name: "Checking", balance: 1000.0, set_aside: false)
          create(:account, user: user, name: "Savings", balance: 2500.0, set_aside: true)

          get dashboard_path
          expect(assigns(:set_aside_total)).to eq(2500.0)
        end

        it "shows the set-aside footnote only when money is reserved" do
          account = create(:account, user: user, name: "Savings", balance: 2500.0, set_aside: true)
          get dashboard_path
          expect(response.body).to include("set aside")

          account.update!(set_aside: false)
          get dashboard_path
          expect(response.body).not_to include("set aside")
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

      context "money in / out this month" do
        let(:account) { create(:account, user: user, name: "Main") }
        let(:income_type) { create(:transaction_type, user: user, kind: "income", name: "Salary") }
        let(:expense_type) { create(:transaction_type, user: user, kind: "expense", name: "Food") }

        it "splits the month into money in and money out" do
          create(:transaction, user: user, account: account, transaction_type: income_type,
                 amount: 500.0, transaction_date: Date.current, description: "Salary")
          create(:transaction, user: user, account: account, transaction_type: expense_type,
                 amount: -200.0, transaction_date: Date.current, description: "Food")

          get dashboard_path
          expect(assigns(:money_in)).to eq(500.0)
          expect(assigns(:money_out)).to eq(200.0)
        end

        it "excludes transactions from other months" do
          create(:transaction, user: user, account: account, transaction_type: income_type,
                 amount: 500.0, transaction_date: Date.current, description: "Salary")
          create(:transaction, user: user, account: account, transaction_type: expense_type,
                 amount: -200.0, transaction_date: 2.months.ago, description: "Old food")

          get dashboard_path
          expect(assigns(:money_in)).to eq(500.0)
          expect(assigns(:money_out)).to eq(0)
        end

        it "excludes transfers from both figures" do
          transfer_out = create(:transaction_type, user: user, kind: "transfer_out", name: "Transfer out")
          create(:transaction, user: user, account: account, transaction_type: income_type,
                 amount: 500.0, transaction_date: Date.current, description: "Salary")
          create(:transaction, user: user, account: account, transaction_type: transfer_out,
                 amount: -300.0, transaction_date: Date.current, description: "To savings")

          get dashboard_path
          expect(assigns(:money_in)).to eq(500.0)
          expect(assigns(:money_out)).to eq(0)
        end

        it "returns 0 when user has no transactions this month" do
          get dashboard_path
          expect(assigns(:money_in)).to eq(0)
          expect(assigns(:money_out)).to eq(0)
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
          expect(assigns(:currency)).to eq(space.currency)
        end
      end
    end

    describe "summary blocks rendering" do
      it "renders the money in / out cells" do
        get dashboard_path
        expect(response.body).to include("flow-cells")
        expect(response.body).to include(I18n.t("home.show.stats.total_balance"))
      end

      it "shows the debts summary only when a debt exists" do
        get dashboard_path
        expect(response.body).not_to include("debt-summary")

        create(:debt, user: user, name: "Alice", direction: "lent",
               status: "ongoing", total_lent: 1000.0, total_reimbursed: 0.0)
        get dashboard_path
        expect(response.body).to include("debt-summary")
        expect(response.body).to include(I18n.t("home.show.stats.owed_to_me"))
        expect(response.body).to include(I18n.t("home.show.stats.i_owe"))
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

      it "redirects to the landing page" do
        get root_path
        expect(response).to redirect_to(landing_path)
      end
    end
  end
end
