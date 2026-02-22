# frozen_string_literal: true

require "rails_helper"

RSpec.describe TransactionItemComponent, type: :component do
  let(:user) { create(:user, currency: "USD") }
  let(:transaction_type) { create(:transaction_type, user: user, kind: "income", name: "Salary") }
  let(:account) { create(:account, user: user, name: "Bank Account") }
  let(:transaction) do
    create(:transaction,
      user: user,
      transaction_type: transaction_type,
      account: account,
      amount: 1000,
      description: "Monthly salary",
      transaction_date: Date.today
    )
  end

  before do
    # Stub current_user in the helper context that ViewComponent uses
    allow_any_instance_of(ActionView::Base).to receive(:current_user).and_return(user)
  end

  it "renders transaction item" do
    render_inline(described_class.new(transaction: transaction))

    expect(rendered_content).to include("transaction-item")
    expect(rendered_content).to include("Salary")
    expect(rendered_content).to include("Monthly salary")
    expect(rendered_content).to include("Bank Account")
  end

  it "includes accessible name in link" do
    render_inline(described_class.new(transaction: transaction))

    expect(rendered_content).to match(/aria[_-]label.*Salary/i)
  end

  context "with income transaction" do
    it "applies income icon class" do
      render_inline(described_class.new(transaction: transaction))

      expect(rendered_content).to include("transaction-item__icon--income")
      expect(rendered_content).to include("transaction-item__amount--income")
    end

    it "shows + prefix for amount" do
      render_inline(described_class.new(transaction: transaction))

      expect(rendered_content).to include("+")
    end
  end

  context "with expense transaction" do
    let(:transaction_type) { create(:transaction_type, user: user, kind: "expense", name: "Groceries") }

    it "applies expense icon class" do
      render_inline(described_class.new(transaction: transaction))

      expect(rendered_content).to include("transaction-item__icon--expense")
      expect(rendered_content).to include("transaction-item__amount--expense")
    end

    it "shows - prefix for amount" do
      render_inline(described_class.new(transaction: transaction))

      expect(rendered_content).to include("-")
    end
  end

  context "with debt transaction" do
    let(:transaction_type) { create(:transaction_type, user: user, kind: "debt_in", name: "Loan") }

    it "applies debt icon class" do
      render_inline(described_class.new(transaction: transaction))

      expect(rendered_content).to include("transaction-item__icon--debt")
    end
  end

  context "with transfer transaction" do
    let(:transaction_type) { create(:transaction_type, user: user, kind: "transfer_in", name: "Transfer") }

    it "applies transfer icon class" do
      render_inline(described_class.new(transaction: transaction))

      expect(rendered_content).to include("transaction-item__icon--transfer")
    end
  end

  context "with note" do
    let(:transaction) do
      create(:transaction,
        user: user,
        transaction_type: transaction_type,
        account: account,
        amount: 1000,
        description: "Monthly salary",
        note: "Extra bonus this month",
        transaction_date: Date.today
      )
    end

    it "displays note indicator" do
      render_inline(described_class.new(transaction: transaction))

      expect(rendered_content).to include("transaction-item__note")
    end
  end

  context "without account" do
    let(:transaction) do
      build_stubbed(:transaction,
        user: user,
        transaction_type: transaction_type,
        account: nil,
        amount: 1000,
        description: "Cash payment",
        transaction_date: Date.today
      )
    end

    it "does not display account name" do
      render_inline(described_class.new(transaction: transaction))

      expect(rendered_content).not_to include("transaction-item__account")
    end
  end

  describe "accessibility" do
    it "marks decorative icons as aria-hidden" do
      render_inline(described_class.new(transaction: transaction))

      expect(rendered_content).to match(/class="transaction-item__icon[^"]*"[^>]*aria-hidden="true"|aria-hidden="true"[^>]*class="transaction-item__icon/)
      expect(rendered_content).to match(/class="transaction-item__chevron"[^>]*aria-hidden="true"|aria-hidden="true"[^>]*class="transaction-item__chevron/)
    end

    it "includes aria-label on link" do
      render_inline(described_class.new(transaction: transaction))

      expect(rendered_content).to match(/aria[_-]label/i)
      expect(rendered_content).to include("Salary")
    end
  end

  describe "collection rendering" do
    let(:transactions) do
      [
        create(:transaction, user: user, transaction_type: transaction_type, amount: 100, description: "Transaction 1"),
        create(:transaction, user: user, transaction_type: transaction_type, amount: 200, description: "Transaction 2"),
        create(:transaction, user: user, transaction_type: transaction_type, amount: 300, description: "Transaction 3")
      ]
    end

    it "renders multiple transaction items" do
      render_inline(described_class.with_collection(transactions, transaction: :itself))

      expect(rendered_content).to include("transaction-item")
      expect(rendered_content).to include("Transaction 1")
      expect(rendered_content).to include("Transaction 2")
      expect(rendered_content).to include("Transaction 3")
    end
  end
end
