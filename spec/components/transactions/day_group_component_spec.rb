# frozen_string_literal: true

require "rails_helper"

RSpec.describe Transactions::DayGroupComponent, type: :component do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:account) { create(:account, space: space, name: "Wave") }
  let(:date) { Date.new(2026, 3, 5) }
  let(:expense_type) { create(:transaction_type, space: space, kind: "expense", name: "Groceries") }
  let(:income_type) { create(:transaction_type, space: space, kind: "income", name: "Salary") }
  let(:transfer_type) { create(:transaction_type, space: space, kind: "transfer_out", name: "Transfer") }
  let(:expense) { create(:transaction, space: space, account: account, transaction_type: expense_type, amount: -12_000, transaction_date: date) }
  let(:income) { create(:transaction, space: space, account: account, transaction_type: income_type, amount: 50_000, transaction_date: date) }
  let(:transfer) { create(:transaction, space: space, account: account, transaction_type: transfer_type, amount: -20_000, transaction_date: date) }
  let(:transactions) { [ income, expense, transfer ] }

  before { stub_current_space(space) }

  context "on the dashboard (space scope)" do
    let(:rendered) { render_inline(described_class.new(date: date, transactions: transactions)) }

    it "heads the group with the full date" do
      expect(rendered.at_css("h3.transaction-group__date").text).to eq("March 05, 2026")
    end

    it "totals the day without transfers" do
      expect(rendered.at_css(".transaction-group__total").text).to eq("+ 38,000 FCFA")
    end

    it "renders one item per transaction" do
      items = rendered.css(".transaction-group__items a.transaction-item")
      expect(items.size).to eq(3)
      expect(items.map { |i| i["href"] }).to include("/en/transactions/#{expense.id}")
    end
  end

  context "on an account page (account scope)" do
    let(:rendered) { render_inline(described_class.new(date: date, transactions: transactions, day_total_scope: :account)) }

    it "counts transfers in the day total" do
      expect(rendered.at_css(".transaction-group__total").text).to eq("+ 18,000 FCFA")
    end
  end

  context "when the day only holds an opening balance" do
    let(:initial_type) { create(:transaction_type, space: space, kind: "initial_balance", name: "Opening") }
    let(:transactions) { [ create(:transaction, space: space, account: account, transaction_type: initial_type, amount: 100_000, transaction_date: date) ] }
    let(:rendered) { render_inline(described_class.new(date: date, transactions: transactions)) }

    it "says the day is off totals" do
      total = rendered.at_css(".transaction-group__total")
      expect(total["class"]).to include("transaction-group__total--muted")
      expect(total.text).to eq("off totals")
    end
  end

  context "inside a category page" do
    let(:rendered) do
      render_inline(described_class.new(date: date, transactions: [ expense ], category: expense_type, subcategory_hint: true))
    end

    it "uses the short date and sums the lines with a sign" do
      expect(rendered.at_css(".transaction-group__date").text).to eq(I18n.l(date, format: :day_month))
      expect(rendered.at_css(".transaction-group__total").text).to eq("− 12,000 FCFA")
    end

    it "renders the items in category context" do
      subtitle = rendered.at_css(".transaction-item__account--wrap")
      expect(subtitle.text).to include("No sub-category")
      expect(subtitle.text).to include("Wave")
    end
  end
end
