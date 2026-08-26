# frozen_string_literal: true

require "rails_helper"

RSpec.describe WriteOffDebtService do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  it "closes a lent debt as written off, moving no money" do
    debt = create(:debt, space: space, direction: "lent", total_lent: 50_000, total_reimbursed: 15_000)

    expect(described_class.new(debt, user: user).call).to be(true)

    debt.reload
    expect(debt).to be_written_off
    expect(debt.total_lent).to eq(50_000)        # unchanged
    expect(debt.total_reimbursed).to eq(15_000)  # unchanged — the ledger stays out of it
    expect(space.debts.ongoing).not_to include(debt)

    txn = debt.transactions.order(:created_at).last
    expect(txn.transaction_type.kind).to eq("debt_writeoff")
    expect(txn.transaction_type.name).to eq("Written off")
    expect(txn.amount.abs).to eq(35_000)         # the remaining balance
    expect(txn.account).to be_nil
  end

  it "closes a forgiven borrowed debt with the right label" do
    debt = create(:debt, space: space, direction: "borrowed", total_lent: 80_000, total_reimbursed: 0)

    described_class.new(debt, user: user).call

    expect(debt.reload).to be_written_off
    expect(debt.transactions.last.transaction_type.name).to eq("Debt forgiven")
  end

  it "won't write off a debt with nothing outstanding" do
    settled = create(:debt, space: space, total_lent: 1_000, total_reimbursed: 1_000) # auto-closes to paid
    expect(described_class.new(settled, user: user).call).to be(false)
  end

  it "keeps written-off debts out of the ongoing totals but in history" do
    debt = create(:debt, space: space, direction: "lent", total_lent: 20_000, total_reimbursed: 0)
    described_class.new(debt, user: user).call

    expect(space.debts.ongoing.lent.sum("total_lent - total_reimbursed")).to eq(0)
    expect(space.debts.written_off).to include(debt.reload)
    expect(debt.transactions.count).to eq(1) # the write-off entry remains
  end
end
