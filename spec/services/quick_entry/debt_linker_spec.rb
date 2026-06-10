# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuickEntry::DebtLinker do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  def income_draft(amount: 25_000, desc: "Remboursement 25k par Julius")
    QuickEntry::Draft.new(
      kind: "income", amount: amount, account_name: nil,
      transaction_type_name: TransactionTaxonomy.name("refund", :en),
      transaction_date: Date.current, description: desc, debt_id: nil, unresolved: []
    )
  end

  it "links an income repayment to an ongoing debt with the named person (debt_in)" do
    debt = create(:debt, user: user, name: "Julius", direction: "lent")

    linked = described_class.link(income_draft, text: "Remboursement 25k par Julius", space: space)

    expect(linked.kind).to eq("debt_in")
    expect(linked.debt_id).to eq(debt.id)
    expect(linked.transaction_type_name).to be_nil
    expect(linked).to be_confident
  end

  it "links an expense to a debt as a repayment made (debt_out)" do
    debt = create(:debt, user: user, name: "Ama", direction: "borrowed")
    draft = income_draft.with(kind: "expense", transaction_type_name: TransactionTaxonomy.name("groceries", :en))

    linked = described_class.link(draft, text: "paid Ama 5000", space: space)

    expect(linked.kind).to eq("debt_out")
    expect(linked.debt_id).to eq(debt.id)
  end

  it "leaves the draft untouched when no ongoing debt matches the utterance" do
    create(:debt, user: user, name: "Julius", direction: "lent")

    draft = income_draft
    expect(described_class.link(draft, text: "Remboursement 25k par Sosthène", space: space)).to eq(draft)
  end

  it "is accent- and case-insensitive on the person name" do
    debt = create(:debt, user: user, name: "Sosthène", direction: "lent")

    linked = described_class.link(income_draft, text: "remboursement de sosthene", space: space)
    expect(linked.debt_id).to eq(debt.id)
  end
end
