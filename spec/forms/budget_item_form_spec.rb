# frozen_string_literal: true

require "rails_helper"

RSpec.describe BudgetItemForm do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:month) { Date.current.beginning_of_month }

  def build_form(payload = {})
    described_class.new(space, {
      kind: "expense",
      transaction_type_name: "Rent",
      amount: 250_000,
      frequency: "monthly",
      starts_on: month
    }.merge(payload))
  end

  it "creates the item, its type, and materializes the current month's entry" do
    form = build_form
    expect(form.submit).to be true

    item = form.budget_item
    expect(item.transaction_type.name).to eq("🏠 Rent") # canonicalized by the taxonomy
    expect(item.frequency).to eq("monthly")
    expect(space.budget_entries.for_month(month).sole.planned_amount).to eq(250_000)
  end

  it "rejects invalid frequencies and duplicate active items" do
    expect(build_form(frequency: "irregular")).to be_invalid

    build_form.submit
    dup = build_form
    expect(dup.submit).to be false
    expect(dup.errors[:transaction_type_name]).to be_present
  end

  it "on edit, updates current and future entries" do
    form = build_form
    form.submit
    item = form.budget_item

    edit = described_class.new(space, budget_item: item, amount: 300_000)
    expect(edit.submit).to be true
    expect(space.budget_entries.for_month(month).sole.planned_amount).to eq(300_000)
  end

  it "creates a transfer line between two accounts" do
    from = create(:account, space: space, name: "Bank")
    create(:account, space: space, name: "Savings")

    form = described_class.new(space, kind: "transfer", from_account_name: "Bank",
                                      to_account_name: "Savings", amount: 100_000,
                                      frequency: "monthly", starts_on: month)
    expect(form.submit).to be true
    item = form.budget_item
    expect(item.from_account).to eq(from)
    expect(item.transaction_type).to be_nil
    expect(space.budget_entries.for_month(month).sole.kind).to eq("transfer")
  end

  it "rejects a transfer to the same account" do
    form = described_class.new(space, kind: "transfer", from_account_name: "Bank",
                                      to_account_name: "bank", amount: 100_000, frequency: "monthly")
    expect(form).to be_invalid
  end

  it "creates a debt line resolving the person to a debt" do
    debt = create(:debt, space: space, direction: "lent", name: "Georges")

    form = described_class.new(space, kind: "debt_in", contact_name: "Georges",
                                      amount: 50_000, frequency: "monthly", starts_on: month)
    expect(form.submit).to be true
    expect(form.budget_item.debt).to eq(debt)
    expect(space.budget_entries.for_month(month).sole.kind).to eq("debt_in")
  end
end
