# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuickEntry::DebtLinker do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  def draft(kind:, amount: 25_000, type_name: nil)
    QuickEntry::Draft.new(kind: kind, amount: amount, transaction_type_name: type_name,
                          transaction_date: Date.current, description: "x")
  end

  it "auto-links an income repayment to the named debt (debt_in — direction is clear)" do
    debt = create(:debt, user: user, name: "Julius", direction: "lent")

    linked = described_class.link(draft(kind: "income"), text: "Remboursement 25k par Julius", space: space)

    expect(linked.kind).to eq("debt_in")
    expect(linked.debt_id).to eq(debt.id)
    expect(linked).to be_confident
  end

  it "auto-links a keyword debt (debt_out) to the named debt" do
    debt = create(:debt, user: user, name: "Ama", direction: "borrowed")

    linked = described_class.link(draft(kind: "debt_out"), text: "remboursé Ama 5000", space: space)

    expect(linked.kind).to eq("debt_out")
    expect(linked.debt_id).to eq(debt.id)
    expect(linked).to be_confident
  end

  it "routes a bare mention with no direction to the debt form (no auto-create)" do
    create(:debt, user: user, name: "Julius", direction: "lent")

    linked = described_class.link(draft(kind: "expense"), text: "2000 Julius", space: space)

    expect(linked.contact_name).to eq("Julius")
    expect(linked.direction).to eq("lent")
    expect(linked.debt_id).to be_nil
    expect(linked).not_to be_confident
  end

  it "keeps a categorised expense as an expense even when a known person is mentioned" do
    create(:debt, user: user, name: "Julius", direction: "lent")
    categorised = draft(kind: "expense", type_name: TransactionTaxonomy.name("groceries", :en))

    expect(described_class.link(categorised, text: "2000 groceries with Julius", space: space)).to eq(categorised)
  end

  it "leaves the draft untouched when no ongoing debt matches" do
    create(:debt, user: user, name: "Julius", direction: "lent")
    d = draft(kind: "income")

    expect(described_class.link(d, text: "Remboursement par Sosthène", space: space)).to eq(d)
  end

  it "matches the person accent- and case-insensitively" do
    debt = create(:debt, user: user, name: "Sosthène", direction: "lent")

    linked = described_class.link(draft(kind: "income"), text: "remboursement de sosthene", space: space)
    expect(linked.debt_id).to eq(debt.id)
  end
end
