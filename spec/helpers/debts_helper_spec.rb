# frozen_string_literal: true

require "rails_helper"

RSpec.describe DebtsHelper, type: :helper do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  before do
    travel_to Time.zone.local(2026, 9, 2, 12)
    helper.define_singleton_method(:current_space) { nil }
    allow(helper).to receive(:current_space).and_return(space)
  end

  # The plan's monthly amount is set once and never recomputed, so the schedule
  # has to count installments from what is still owed — otherwise the card states
  # a number of payments that does not add up to the balance.
  describe "#debt_schedule" do
    def plan(lent:, reimbursed:, monthly:, ends_on:)
      debt = create(:debt, user: user, name: "Jacob", direction: "lent",
                           total_lent: lent, total_reimbursed: reimbursed,
                           deadline: Date.new(2026, 12, 2))
      create(:budget_item, space: space, debt: debt, kind: "debt_in", transaction_type: nil,
                           amount: monthly, starts_on: Date.new(2026, 8, 1), ends_on: ends_on)
      helper.debt_schedule(debt.reload)
    end

    it "counts the payments the balance actually needs, not the months left on the line" do
      # 30 000 still owed at 10 000 a month is three payments — whatever the line
      # was bounded to when it was written.
      schedule = plan(lent: 30_000, reimbursed: 0, monthly: 10_000, ends_on: Date.new(2026, 10, 1))

      expect(schedule[:installments]).to eq(3)
      expect(schedule[:monthly] * schedule[:installments]).to eq(30_000)
    end

    it "settles the month the last payment lands, counting from next month" do
      schedule = plan(lent: 30_000, reimbursed: 0, monthly: 10_000, ends_on: Date.new(2026, 10, 1))

      # October, November, December — repayment starts the month after the loan.
      expect(schedule[:ends_on]).to eq(Date.new(2026, 12, 1))
    end

    it "shrinks as the debt is repaid, with nothing to resync" do
      schedule = plan(lent: 30_000, reimbursed: 15_000, monthly: 10_000, ends_on: Date.new(2026, 12, 1))

      expect(schedule[:installments]).to eq(2)
    end

    it "rounds a partial last payment up rather than losing it" do
      schedule = plan(lent: 25_000, reimbursed: 0, monthly: 10_000, ends_on: Date.new(2026, 12, 1))

      expect(schedule[:installments]).to eq(3)
    end
  end
end
