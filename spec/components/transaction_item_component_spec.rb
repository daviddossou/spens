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

  it "renders transaction item" do
    render_inline(described_class.new(transaction: transaction))

    expect(rendered_content).to include("transaction-item")
    expect(rendered_content).to include("Salary")
    # The free-text description no longer appears in the list (it lives on the
    # detail page); the subtitle is the account.
    expect(rendered_content).not_to include("Monthly salary")
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
      # Amounts stay dark now; the coloured icon carries the family.
      expect(rendered_content).to include("transaction-item__amount--strong")
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
      expect(rendered_content).to include("transaction-item__amount--strong")
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

    it "keeps the list sober — no note indicator (the note lives on the detail page)" do
      render_inline(described_class.new(transaction: transaction))

      expect(rendered_content).not_to include("transaction-item__note")
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

      # Titles are composed from the category, not the free-text description.
      expect(rendered_content.scan("transaction-item__content").size).to eq(3)
      expect(rendered_content).to include("Salary")
    end
  end

  context "with a debt write-off (no money moved)" do
    let(:debt) { create(:debt, user: user, name: "Georges", direction: "lent") }
    let(:writeoff_type) { create(:transaction_type, user: user, kind: "debt_writeoff", name: "Written off") }
    let(:writeoff) do
      create(:transaction, user: user, transaction_type: writeoff_type, account: nil, debt: debt,
                           amount: 35_000, description: "Georges's debt written off")
    end

    it "renders the amount muted, with no + or - sign, and a composed title" do
      render_inline(described_class.new(transaction: writeoff))

      expect(rendered_content).to include("transaction-item__amount--muted")
      expect(rendered_content).to include("transaction-item__icon--neutral")
      expect(rendered_content).to include("Georges")
      # The amount shows with no leading sign (not "-35" or "+35").
      expect(rendered_content).not_to match(/[-+]\s*35/)
    end
  end
end
