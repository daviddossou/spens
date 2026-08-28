# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReactivateDebtService do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  it "brings a written-off debt back as ongoing for its remaining balance" do
    debt = create(:debt, space: space, direction: "lent", total_lent: 50_000, total_reimbursed: 15_000)
    WriteOffDebtService.new(debt, user: user).call
    expect(debt.reload).to be_written_off

    expect(described_class.new(debt, user: user).call).to be(true)

    debt.reload
    expect(debt).to be_ongoing
    expect(debt.remaining_balance).to eq(35_000)          # unchanged by the round trip
    expect(space.debts.ongoing).to include(debt)
  end

  it "removes the write-off event so history is clean again" do
    debt = create(:debt, space: space, direction: "lent", total_lent: 20_000, total_reimbursed: 0)
    WriteOffDebtService.new(debt, user: user).call
    expect(debt.reload.transactions.joins(:transaction_type).where(transaction_types: { kind: "debt_writeoff" })).to be_present

    described_class.new(debt, user: user).call

    expect(debt.reload.transactions.joins(:transaction_type).where(transaction_types: { kind: "debt_writeoff" })).to be_empty
  end

  it "re-establishes the repayment plan when the debt has a deadline" do
    debt = create(:debt, space: space, direction: "borrowed", total_lent: 60_000, total_reimbursed: 0,
                         deadline: Date.current >> 3)
    WriteOffDebtService.new(debt, user: user).call

    described_class.new(debt, user: user).call

    expect(debt.reload.repayment_line).to be_present
  end

  it "does nothing to a debt that isn't written off" do
    ongoing = create(:debt, space: space, total_lent: 10_000, total_reimbursed: 0)
    expect(described_class.new(ongoing, user: user).call).to be(false)
  end
end
