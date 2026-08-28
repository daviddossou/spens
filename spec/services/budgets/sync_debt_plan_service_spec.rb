# frozen_string_literal: true

require "rails_helper"

RSpec.describe Budgets::SyncDebtPlanService do
  let(:space) { create(:space) }

  it "spreads the remaining balance over the months to the deadline and bounds the line" do
    travel_to Date.new(2026, 1, 10) do
      debt = create(:debt, space: space, direction: "borrowed",
                           total_lent: 12_000, total_reimbursed: 0, deadline: Date.new(2026, 4, 30))
      item = create(:budget_item, :debt, space: space, debt: debt, kind: "debt_out",
                                          amount: 1_000, starts_on: Date.new(2026, 1, 1))

      described_class.call(debt)

      item.reload
      expect(item.amount).to eq(4_000) # 12000 / 3 months (Feb..Apr — repayment starts next month)
      expect(item.ends_on).to eq(Date.new(2026, 4, 30))
    end
  end

  it "clears the bound when the deadline is removed" do
    travel_to Date.new(2026, 1, 10) do
      debt = create(:debt, space: space, direction: "borrowed", total_lent: 12_000, total_reimbursed: 0)
      item = create(:budget_item, :debt, space: space, debt: debt, kind: "debt_out",
                                          amount: 1_000, starts_on: Date.new(2026, 1, 1),
                                          ends_on: Date.new(2026, 4, 30))

      described_class.call(debt)

      expect(item.reload.ends_on).to be_nil
    end
  end

  it "creates a repayment line when the debt has a deadline but none yet (borrowed → debt_out)" do
    travel_to Date.new(2026, 1, 10) do
      debt = create(:debt, space: space, direction: "borrowed",
                           total_lent: 50_000, total_reimbursed: 0, deadline: Date.new(2026, 5, 31))

      expect { described_class.call(debt) }.to change { space.budget_items.count }.by(1)

      line = space.budget_items.find_by(debt_id: debt.id)
      expect(line.kind).to eq("debt_out")
      expect(line.amount).to eq(12_500) # 50000 / 4 months (Feb..May — repayment starts next month)
      expect(line.starts_on).to eq(Date.new(2026, 2, 1)) # first payment is next month
      expect(line.ends_on).to eq(Date.new(2026, 5, 31))
      expect(line).to be_active
    end
  end

  it "creates a debt_in line for a lent debt" do
    travel_to Date.new(2026, 1, 10) do
      debt = create(:debt, space: space, direction: "lent",
                           total_lent: 12_000, total_reimbursed: 0, deadline: Date.new(2026, 4, 30))

      described_class.call(debt)

      expect(space.budget_items.find_by(debt_id: debt.id).kind).to eq("debt_in")
    end
  end

  it "creates nothing without a deadline" do
    travel_to Date.new(2026, 1, 10) do
      debt = create(:debt, space: space, total_lent: 12_000, total_reimbursed: 0)
      expect { described_class.call(debt) }.not_to change { space.budget_items.count }
    end
  end
end
