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
end
