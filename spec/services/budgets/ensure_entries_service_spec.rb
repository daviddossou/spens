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
end
