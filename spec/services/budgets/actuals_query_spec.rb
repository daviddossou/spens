# frozen_string_literal: true

require "rails_helper"

RSpec.describe Budgets::ActualsQuery do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:month) { Date.new(2026, 7, 1) }
  let(:parent) { create(:transaction_type, space: space, kind: "expense") }
  let(:child) { create(:transaction_type, space: space, kind: "expense", parent: parent) }

  def query
    described_class.new(space: space, month: month)
  end

  def record(type, amount, date: month + 5, account: nil, debt: nil, transfer_group_id: nil)
    create(:transaction, space: space, transaction_type: type, amount: amount,
                         transaction_date: date, account: account, debt: debt,
                         transfer_group_id: transfer_group_id)
  end

  it "sums multiple transactions of the month toward a category entry, subtree included" do
    entry = create(:budget_entry, space: space,
                                  budget_item: create(:budget_item, space: space, transaction_type: parent))
    record(parent, -10_000)
    record(child, -5_000)
    record(child, -5_000)
    record(child, -2_500, date: month >> 1) # outside month

    expect(query.for_entry(entry)).to eq(20_000)
  end

  it "keeps a child-category budget to its own subtree" do
    entry = create(:budget_entry, space: space,
                                  budget_item: create(:budget_item, space: space, transaction_type: child))
    record(parent, -10_000)
    record(child, -5_000)

    expect(query.for_entry(entry)).to eq(5_000)
  end

  it "sums the month's transfers between the budgeted account pair" do
    from = create(:account, space: space, name: "Bank")
    to = create(:account, space: space, name: "Savings")
    other = create(:account, space: space, name: "Cash")
    t_out = create(:transaction_type, space: space, kind: "transfer_out", name: "Transfer out")
    t_in = create(:transaction_type, space: space, kind: "transfer_in", name: "Transfer in")

    item = create(:budget_item, :transfer, space: space, from_account: from, to_account: to, amount: 100_000)
    entry = create(:budget_entry, space: space, budget_item: item, kind: "transfer", transaction_type: nil)

    2.times do
      group = SecureRandom.uuid
      record(t_out, -40_000, account: from, transfer_group_id: group)
      record(t_in, 40_000, account: to, transfer_group_id: group)
    end
    # A transfer to a different account must not count.
    group = SecureRandom.uuid
    record(t_out, -15_000, account: from, transfer_group_id: group)
    record(t_in, 15_000, account: other, transfer_group_id: group)

    expect(query.for_entry(entry)).to eq(80_000)
  end

  it "sums the month's repayments on the budgeted debt, direction-scoped" do
    debt = create(:debt, space: space, direction: "lent", name: "Georges")
    debt_in_type = create(:transaction_type, space: space, kind: "debt_in", name: "Repayment in")

    item = create(:budget_item, :debt, space: space, debt: debt, kind: "debt_in", amount: 50_000)
    entry = create(:budget_entry, space: space, budget_item: item, kind: "debt_in", transaction_type: nil)

    record(debt_in_type, 20_000, debt: debt)
    record(debt_in_type, 15_000, debt: debt)
    record(debt_in_type, 10_000, debt: create(:debt, space: space, direction: "lent", name: "Other"))

    expect(query.for_entry(entry)).to eq(35_000)
  end
end
