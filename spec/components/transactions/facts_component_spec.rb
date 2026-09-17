# frozen_string_literal: true

require "rails_helper"

RSpec.describe Transactions::FactsComponent, type: :component do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:account) { create(:account, space: space, name: "Wave") }
  let(:type) { create(:transaction_type, space: space, kind: "expense", name: "Groceries") }
  let(:debt) { nil }
  let(:transaction) do
    create(:transaction, space: space, account: account, transaction_type: type, debt: debt, amount: -5_000,
                         transaction_date: Date.new(2026, 3, 5))
  end
  let(:editable) { true }

  let(:rendered) { render_inline(described_class.new(transaction: transaction, editable: editable)) }
  let(:rows) { rendered.css(".movement-facts__row") }

  def row(label)
    rows.find { |r| r.at_css(".movement-facts__label").text == label }
  end

  context "when editable" do
    it "opens each fact's selector in the modal" do
      %w[category account date].each do |fact|
        r = row(fact.capitalize)
        expect(r.name).to eq("a")
        expect(r["href"]).to eq("/transactions/#{transaction.id}/facts/#{fact}")
        expect(r["data-turbo-frame"]).to eq("modal")
      end
      expect(row("Category").at_css(".movement-facts__value").text).to eq("Groceries")
      expect(row("Account").at_css(".movement-facts__value").text).to eq("Wave")
      expect(row("Date").at_css(".movement-facts__value").text).to eq("March 05, 2026")
    end

    it "has no debt row" do
      expect(row("Related Debt")).to be_nil
    end

    context "without an account" do
      let(:transaction) { create(:transaction, space: space, account: nil, transaction_type: type, amount: -5_000) }

      it "still offers the account fact, saying there is none" do
        expect(row("Account").at_css(".movement-facts__value").text).to eq("No account")
      end
    end
  end

  context "when not editable" do
    let(:editable) { false }

    it "keeps the category static and links the account to its page" do
      expect(row("Category").name).to eq("div")
      account_row = row("Account")
      expect(account_row["href"]).to eq("/accounts/#{account.id}")
      expect(account_row["data-turbo-frame"]).to eq("_top")
      expect(row("Date")["href"]).to eq("/transactions/#{transaction.id}/facts/date")
    end

    context "without an account" do
      let(:transaction) { create(:transaction, space: space, account: nil, transaction_type: type, amount: -5_000) }

      it "drops the account row" do
        expect(row("Account")).to be_nil
      end
    end

    context "with a related debt" do
      let(:type) { create(:transaction_type, space: space, kind: "debt_out", name: "Loan") }
      let(:debt) { create(:debt, space: space, name: "Georges") }

      it "links to the debt at top level" do
        debt_row = row("Related Debt")
        expect(debt_row.at_css(".movement-facts__value").text).to eq("Georges")
        expect(debt_row["href"]).to eq("/debts/#{debt.id}")
        expect(debt_row["data-turbo-frame"]).to eq("_top")
      end
    end
  end
end
