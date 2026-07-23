# frozen_string_literal: true

# == Schema Information
#
# Table name: budget_items
#
#  id                  :uuid             not null, primary key
#  active              :boolean          default(TRUE), not null
#  amount              :decimal(15, 2)   not null
#  ends_on             :date
#  frequency           :string           not null
#  kind                :string           not null, indexed => [space_id, debt_id]
#  starts_on           :date             not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  debt_id             :uuid             indexed, indexed => [space_id, kind]
#  from_account_id     :uuid             indexed, indexed => [space_id, to_account_id]
#  space_id            :uuid             not null, indexed => [debt_id, kind], indexed => [from_account_id, to_account_id], indexed => [transaction_type_id], indexed
#  to_account_id       :uuid             indexed => [space_id, from_account_id], indexed
#  transaction_type_id :uuid             indexed => [space_id], indexed
#
# Indexes
#
#  index_budget_items_on_debt_id                    (debt_id)
#  index_budget_items_on_from_account_id            (from_account_id)
#  index_budget_items_on_space_and_debt_active      (space_id,debt_id,kind) UNIQUE WHERE (active AND (debt_id IS NOT NULL))
#  index_budget_items_on_space_and_transfer_active  (space_id,from_account_id,to_account_id) UNIQUE WHERE (active AND (from_account_id IS NOT NULL))
#  index_budget_items_on_space_and_type_active      (space_id,transaction_type_id) UNIQUE WHERE (active AND (transaction_type_id IS NOT NULL))
#  index_budget_items_on_space_id                   (space_id)
#  index_budget_items_on_to_account_id              (to_account_id)
#  index_budget_items_on_transaction_type_id        (transaction_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (debt_id => debts.id)
#  fk_rails_...  (from_account_id => accounts.id)
#  fk_rails_...  (space_id => spaces.id)
#  fk_rails_...  (to_account_id => accounts.id)
#  fk_rails_...  (transaction_type_id => transaction_types.id)
#
require "rails_helper"

RSpec.describe BudgetItem do
  describe "validations" do
    it "rejects an unknown frequency and the irregular one" do
      expect(build(:budget_item, frequency: "irregular")).not_to be_valid
      expect(build(:budget_item, frequency: "sometimes")).not_to be_valid
    end

    it "rejects non-positive amounts" do
      expect(build(:budget_item, amount: 0)).not_to be_valid
    end

    it "allows only one active item per type per space" do
      item = create(:budget_item)
      dup = build(:budget_item, space: item.space, transaction_type: item.transaction_type)
      expect(dup).not_to be_valid

      item.update!(active: false)
      expect(dup).to be_valid
    end
  end

  describe "#occurs_in?" do
    let(:start) { Date.new(2026, 9, 1) }

    it "is false before starts_on and after ends_on" do
      item = build(:budget_item, starts_on: start, ends_on: Date.new(2026, 12, 31))
      expect(item.occurs_in?(Date.new(2026, 8, 1))).to be false
      expect(item.occurs_in?(Date.new(2027, 1, 1))).to be false
      expect(item.occurs_in?(Date.new(2026, 12, 15))).to be true
    end

    it "occurs every month for monthly and sub-monthly frequencies" do
      %w[daily weekly biweekly monthly].each do |freq|
        item = build(:budget_item, frequency: freq, starts_on: start)
        expect(item.occurs_in?(Date.new(2026, 10, 1))).to be(true), freq
      end
    end

    it "occurs every third month for quarterly" do
      item = build(:budget_item, frequency: "quarterly", starts_on: start)
      expect(item.occurs_in?(Date.new(2026, 9, 1))).to be true
      expect(item.occurs_in?(Date.new(2026, 10, 1))).to be false
      expect(item.occurs_in?(Date.new(2026, 12, 1))).to be true
      expect(item.occurs_in?(Date.new(2027, 3, 1))).to be true
    end

    it "occurs on the anniversary month for yearly" do
      item = build(:budget_item, frequency: "yearly", starts_on: start)
      expect(item.occurs_in?(Date.new(2026, 9, 1))).to be true
      expect(item.occurs_in?(Date.new(2027, 8, 1))).to be false
      expect(item.occurs_in?(Date.new(2027, 9, 1))).to be true
    end
  end

  describe "#planned_amount_for" do
    it "normalizes sub-monthly frequencies to a monthly total" do
      expect(build(:budget_item, amount: 15_000, frequency: "weekly").planned_amount_for).to eq(65_000)
      expect(build(:budget_item, amount: 12_000, frequency: "biweekly").planned_amount_for).to eq(26_000)
    end

    it "keeps the full amount for monthly and longer" do
      %w[monthly quarterly yearly].each do |freq|
        expect(build(:budget_item, amount: 120_000, frequency: freq).planned_amount_for).to eq(120_000)
      end
    end
  end
end
