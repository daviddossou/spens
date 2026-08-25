# frozen_string_literal: true

require "rails_helper"

RSpec.describe Budgets::EnsureEntriesService do
  let(:space) { create(:space) }
  let(:month) { Date.new(2026, 7, 1) }

  def ensure_month(m = month)
    described_class.new(space: space, month: m).call
  end

  it "materializes an entry per active item and is idempotent" do
    item = create(:budget_item, space: space, amount: 25_000, starts_on: month)
    ensure_month
    expect { ensure_month }.not_to change(space.budget_entries, :count)

    entry = space.budget_entries.sole
    expect(entry.budget_item).to eq(item)
    expect(entry.planned_amount).to eq(25_000)
    expect(entry.kind).to eq("expense")
    expect(entry.month).to eq(month)
  end

  it "skips inactive items and months outside the item window" do
    create(:budget_item, space: space, active: false, starts_on: month)
    create(:budget_item, space: space, starts_on: month >> 2)
    ensure_month
    expect(space.budget_entries).to be_empty
  end

  it "materializes yearly items only in their anniversary month" do
    create(:budget_item, space: space, frequency: "yearly", amount: 120_000, starts_on: Date.new(2026, 12, 1))
    ensure_month(Date.new(2026, 12, 1))
    ensure_month(Date.new(2027, 1, 1))
    ensure_month(Date.new(2027, 12, 1))

    expect(space.budget_entries.pluck(:month)).to contain_exactly(Date.new(2026, 12, 1), Date.new(2027, 12, 1))
    expect(space.budget_entries.pluck(:planned_amount).uniq).to eq([ 120_000 ])
  end

  it "normalizes weekly items into one monthly line" do
    create(:budget_item, space: space, frequency: "weekly", amount: 15_000, starts_on: month)
    ensure_month
    expect(space.budget_entries.sole.planned_amount).to eq(65_000)
  end

  it "retires a debt line once the debt is settled" do
    debt = create(:debt, space: space, direction: "lent", status: "ongoing")
    item = create(:budget_item, :debt, space: space, debt: debt, starts_on: month)
    ensure_month
    expect(space.budget_entries.count).to eq(1)

    debt.update!(status: "paid")
    space.budget_entries.destroy_all
    ensure_month

    expect(item.reload.active).to be false
    expect(space.budget_entries).to be_empty
  end

  it "does not overwrite a manually edited entry on re-run" do
    create(:budget_item, space: space, amount: 25_000, starts_on: month)
    ensure_month
    space.budget_entries.sole.update!(planned_amount: 30_000)
    ensure_month
    expect(space.budget_entries.sole.planned_amount).to eq(30_000)
  end

  describe "rollover" do
    # The service only recomputes carry while the month is current or future, so
    # anchor "now" inside the test month rather than the wall clock.
    before { travel_to(month + 14) }

    let(:june) { month << 1 }
    let(:type) { create(:transaction_type, space: space, kind: "expense") }
    let!(:item) { create(:budget_item, space: space, rollover: true, amount: 500_000, starts_on: june, transaction_type: type) }

    def spend(amount, date)
      create(:transaction, space: space, transaction_type: type, amount: -amount, transaction_date: date)
    end

    def july_entry
      space.budget_entries.find_by(month: month)
    end

    it "carries last month's unspent remainder into this month's planned amount" do
      ensure_month(june)
      spend(250_000, june + 10)
      ensure_month

      expect(july_entry.planned_amount).to eq(750_000)
      expect(july_entry.carried_amount).to eq(250_000)
    end

    it "recomputes the carry on re-run while the month is current" do
      ensure_month(june)
      spend(250_000, june + 10)
      ensure_month
      spend(100_000, june + 15)
      ensure_month

      expect(july_entry.planned_amount).to eq(650_000)
      expect(july_entry.carried_amount).to eq(150_000)
    end

    it "adjusts a manually overridden month by the carry delta only" do
      ensure_month(june)
      spend(250_000, june + 10)
      ensure_month
      july_entry.update!(planned_amount: 800_000)
      spend(100_000, june + 15)
      ensure_month

      expect(july_entry.reload.planned_amount).to eq(700_000)
      expect(july_entry.carried_amount).to eq(150_000)
    end

    it "never carries a negative remainder" do
      ensure_month(june)
      spend(600_000, june + 10)
      ensure_month

      expect(july_entry.planned_amount).to eq(500_000)
      expect(july_entry.carried_amount).to eq(0)
    end

    it "leaves non-rollover items untouched" do
      item.update!(rollover: false)
      ensure_month(june)
      spend(250_000, june + 10)
      ensure_month

      expect(july_entry.planned_amount).to eq(500_000)
      expect(july_entry.carried_amount).to eq(0)
    end
  end
end
