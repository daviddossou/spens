# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompensateDebtsService do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  it "offsets the smaller side against the larger, closing the small debt" do
    lent = create(:debt, space: space, name: "David", direction: "lent", total_lent: 45_000, total_reimbursed: 0)
    borrowed = create(:debt, space: space, name: "David", direction: "borrowed", total_lent: 270_000, total_reimbursed: 0)
    relation = DebtRelation.for(lent)

    expect(described_class.new(relation, user: user).call).to be(true)

    expect(lent.reload).to be_paid                     # the small side clears
    expect(borrowed.reload.remaining_balance).to eq(225_000) # the large side drops to the net
  end

  it "records a dated movement on each side, deleting nothing" do
    lent = create(:debt, space: space, name: "David", direction: "lent", total_lent: 45_000)
    borrowed = create(:debt, space: space, name: "David", direction: "borrowed", total_lent: 270_000)
    relation = DebtRelation.for(lent)

    expect { described_class.new(relation, user: user).call }
      .to change { lent.transactions.count }.by(1)
      .and change { borrowed.transactions.count }.by(1)
  end

  it "does nothing when money flows only one way" do
    lent = create(:debt, space: space, name: "Karim", direction: "lent", total_lent: 100_000)
    relation = DebtRelation.for(lent)
    expect(described_class.new(relation, user: user).call).to be(false)
  end
end
