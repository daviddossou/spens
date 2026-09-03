# frozen_string_literal: true

# == Schema Information
#
# Table name: goals
#
#  id            :uuid             not null, primary key
#  deadline      :date
#  name          :string           not null
#  target_amount :decimal(15, 2)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :uuid             not null, indexed
#  space_id      :uuid             not null, indexed
#
# Indexes
#
#  index_goals_on_account_id  (account_id) UNIQUE
#  index_goals_on_space_id    (space_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (space_id => spaces.id)
#
require "rails_helper"

RSpec.describe Goal, type: :model do
  subject(:goal) { build(:goal) }

  describe "associations" do
    it { is_expected.to belong_to(:space) }
    it { is_expected.to belong_to(:account) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }

    it "allows a nil target amount (no target yet)" do
      goal.target_amount = nil
      expect(goal).to be_valid
    end

    it "rejects a zero or negative target" do
      goal.target_amount = 0
      expect(goal).not_to be_valid
    end

    it "allows only one goal per account" do
      existing = create(:goal)
      dup = build(:goal, account: existing.account, space: existing.space)
      expect(dup).not_to be_valid
    end
  end

  describe "#remaining" do
    it "is target minus the account balance, floored at zero" do
      account = create(:account, balance: 3_000)
      goal = create(:goal, account: account, space: account.space, target_amount: 10_000)
      expect(goal.remaining).to eq(7_000)
    end

    it "is nil without a target" do
      expect(build(:goal, target_amount: nil).remaining).to be_nil
    end
  end

  describe "the account it lives on" do
    it "marks it set aside — a goal is what set aside means" do
      account = create(:account, set_aside: false)
      create(:goal, space: account.space, account: account)

      expect(account.reload.set_aside).to be(true)
    end

    it "retires the plan line it owns when it is dropped" do
      account = create(:account)
      goal = create(:goal, space: account.space, account: account, target_amount: 100_000,
                           deadline: Date.current.end_of_month >> 2)
      Budgets::SyncGoalPlanService.call(goal) # the form's own path
      line = account.space.budget_items.active.find_by(kind: "transfer", to_account_id: account.id)
      expect(line).to be_present

      goal.destroy!

      expect(line.reload.active).to be(false)
    end

    it "leaves the flag alone when the goal is dropped: it is still a savings account" do
      account = create(:account, set_aside: false)
      goal = create(:goal, space: account.space, account: account)
      goal.destroy!

      expect(account.reload.set_aside).to be(true)
    end
  end
end
