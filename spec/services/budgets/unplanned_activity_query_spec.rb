# frozen_string_literal: true

require "rails_helper"

RSpec.describe Budgets::UnplannedActivityQuery do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:month) { Date.new(2026, 7, 1) }
  let(:parent) { create(:transaction_type, space: space, kind: "expense") }
  let(:child) { create(:transaction_type, space: space, kind: "expense", parent: parent) }

  # Anchor "now" inside the queried month so budget-entry factories (which default
  # month: Date.current) land on the month under test.
  before { travel_to(month + 14) }

  def query
    described_class.new(space: space, month: month).call
  end

  def record(type, amount, date: month + 5, account: nil, transfer_group_id: nil)
    create(:transaction, space: space, transaction_type: type, amount: amount,
                         transaction_date: date, account: account,
                         transfer_group_id: transfer_group_id)
  end

  it "sums the month's expenses on categories no budget line covers, largest first" do
    covered = create(:transaction_type, space: space, kind: "expense")
    create(:budget_entry, space: space,
                          budget_item: create(:budget_item, space: space, transaction_type: covered))
    surprise = create(:transaction_type, space: space, kind: "expense", name: "Repairs")
    other = create(:transaction_type, space: space, kind: "expense", name: "Gifts")

    record(covered, -10_000)
    record(surprise, -5_000)
    record(surprise, -3_000)
    record(other, -20_000)
    record(surprise, -1_000, date: month >> 1) # outside month

    expect(query[:expense]).to eq(other => { amount: 20_000, prev: 0 },
                                  surprise => { amount: 8_000, prev: 0 })
  end

  it "reports last month's activity on the same category as prev" do
    surprise = create(:transaction_type, space: space, kind: "expense", name: "Repairs")
    record(surprise, -5_000)
    record(surprise, -12_000, date: (month << 1) + 3)

    expect(query[:expense]).to eq(surprise => { amount: 5_000, prev: 12_000 })
  end

  it "treats a budget line on a parent as covering its subtree" do
    create(:budget_entry, space: space,
                          budget_item: create(:budget_item, space: space, transaction_type: parent))
    record(child, -5_000)

    expect(query[:expense]).to be_empty
  end

  it "reports unplanned income separately from expenses" do
    covered = create(:transaction_type, space: space, kind: "income", name: "Salary")
    create(:budget_entry, space: space, kind: "income",
                          budget_item: create(:budget_item, space: space, kind: "income", transaction_type: covered))
    bonus = create(:transaction_type, space: space, kind: "income", name: "Bonus")

    record(covered, 100_000)
    record(bonus, 30_000)

    expect(query[:income]).to eq(bonus => { amount: 30_000, prev: 0 })
    expect(query[:expense]).to be_empty
  end

  it "reports transfers between account pairs no transfer budget line covers" do
    bank = create(:account, space: space, name: "Bank")
    savings = create(:account, space: space, name: "Savings")
    cash = create(:account, space: space, name: "Cash")
    t_out = create(:transaction_type, space: space, kind: "transfer_out", name: "Transfer out")
    t_in = create(:transaction_type, space: space, kind: "transfer_in", name: "Transfer in")

    item = create(:budget_item, :transfer, space: space, from_account: bank, to_account: savings)
    create(:budget_entry, space: space, budget_item: item, kind: "transfer", transaction_type: nil)

    # Budgeted pair: must not surface.
    group = SecureRandom.uuid
    record(t_out, -40_000, account: bank, transfer_group_id: group)
    record(t_in, 40_000, account: savings, transfer_group_id: group)

    # Unbudgeted pair, twice: surfaces summed.
    2.times do
      group = SecureRandom.uuid
      record(t_out, -15_000, account: bank, transfer_group_id: group)
      record(t_in, 15_000, account: cash, transfer_group_id: group)
    end

    expect(query[:transfers]).to eq([ { from: bank, to: cash, amount: 30_000, prev: 0 } ])
  end

  it "treats a source-less transfer line as covering money into that destination from any source" do
    bank = create(:account, space: space, name: "Bank")
    savings = create(:account, space: space, name: "Savings")
    mobile = create(:account, space: space, name: "Mobile Money")
    t_out = create(:transaction_type, space: space, kind: "transfer_out", name: "Transfer out")
    t_in = create(:transaction_type, space: space, kind: "transfer_in", name: "Transfer in")

    # Savings-goal plan: a source-less line into Savings.
    item = create(:budget_item, space: space, kind: "transfer", from_account: nil, to_account: savings, amount: 50_000)
    create(:budget_entry, space: space, budget_item: item, kind: "transfer", transaction_type: nil)

    # Two contributions into Savings from different sources — both covered.
    g1 = SecureRandom.uuid
    record(t_out, -45_000, account: bank, transfer_group_id: g1)
    record(t_in, 45_000, account: savings, transfer_group_id: g1)
    g2 = SecureRandom.uuid
    record(t_out, -25_000, account: mobile, transfer_group_id: g2)
    record(t_in, 25_000, account: savings, transfer_group_id: g2)
    # A transfer to a different destination still surfaces.
    g3 = SecureRandom.uuid
    record(t_out, -10_000, account: bank, transfer_group_id: g3)
    record(t_in, 10_000, account: mobile, transfer_group_id: g3)

    expect(query[:transfers]).to eq([ { from: bank, to: mobile, amount: 10_000, prev: 0 } ])
  end
end
