# frozen_string_literal: true

require "rails_helper"

RSpec.describe Budgets::SyncGoalPlanService do
  let(:space) { create(:space) }

  def build_account(balance:, goal:, deadline:)
    create(:account, space: space, balance: balance, saving_goal: goal, saving_goal_deadline: deadline)
  end

  def goal_line(account)
    space.budget_items.find_by(kind: "transfer", to_account_id: account.id, from_account_id: nil)
  end

  it "creates a source-less monthly transfer spreading the remainder to the deadline" do
    travel_to Date.new(2026, 1, 15) do
      account = build_account(balance: 0, goal: 30_000, deadline: Date.new(2026, 6, 30))
      described_class.call(account)

      line = goal_line(account)
      expect(line).to be_present
      expect(line.amount).to eq(5_000) # 30000 / 6 months (Jan..Jun inclusive)
      expect(line.starts_on).to eq(Date.new(2026, 1, 1))
      expect(line.ends_on).to eq(Date.new(2026, 6, 30))
      expect(line).to be_active
      expect(space.budget_entries.where(budget_item: line)).to be_present
    end
  end

  it "spreads only the remaining amount, not the whole goal" do
    travel_to Date.new(2026, 1, 15) do
      account = build_account(balance: 10_000, goal: 30_000, deadline: Date.new(2026, 5, 31))
      described_class.call(account)

      # remaining 20000 over Jan..May (5 months) = 4000
      expect(goal_line(account).amount).to eq(4_000)
    end
  end

  it "retires the line when the deadline is cleared" do
    travel_to Date.new(2026, 1, 15) do
      account = build_account(balance: 0, goal: 30_000, deadline: Date.new(2026, 6, 30))
      described_class.call(account)

      account.update!(saving_goal_deadline: nil)
      described_class.call(account)

      expect(goal_line(account)).not_to be_active
    end
  end

  it "creates no line once the goal is already reached" do
    travel_to Date.new(2026, 1, 15) do
      account = build_account(balance: 30_000, goal: 30_000, deadline: Date.new(2026, 6, 30))
      described_class.call(account)

      expect(goal_line(account)).to be_nil
    end
  end
end
