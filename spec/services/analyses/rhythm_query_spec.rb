# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analyses::RhythmQuery do
  let(:space) { create(:space) }
  let(:account) { create(:account, space: space) }
  let(:groceries) { create(:transaction_type, space: space, kind: "expense", name: "Provisions X") }
  let(:zem) { create(:transaction_type, space: space, kind: "expense", name: "Zem X") }

  def spend(amount, on:, type: groceries)
    create(:transaction, space: space, account: account, transaction_type: type,
                         amount: -amount, transaction_date: on)
  end

  it "gives one bar per day over the month, the future grey rather than absent" do
    bom = Date.current.beginning_of_month
    spend(62_000, on: bom + 2)
    spend(3_000, on: bom + 2, type: zem)
    spend(10_000, on: bom)

    query = described_class.new(space: space, period: Analyses::Period.new("month"))
    expect(query.units.size).to eq(Date.current.end_of_month.day)
    expect(query.units.count(&:future)).to eq((Date.current.end_of_month - Date.current).to_i)
    expect(query.units.find { |u| u.starts_on == bom + 2 }.amount).to eq(65_000)
  end

  it "names the biggest unit and its top category" do
    bom = Date.current.beginning_of_month
    spend(62_000, on: bom + 2)
    spend(70_000, on: bom + 3, type: zem)

    query = described_class.new(space: space, period: Analyses::Period.new("month"))
    expect(query.biggest.starts_on).to eq(bom + 3)
    expect(query.biggest_category).to eq("Zem X")
  end

  it "groups by month over twelve months, transfers and debts excluded" do
    debt_type = create(:transaction_type, space: space, kind: "debt_out", name: "Prêt X")
    spend(40_000, on: 2.months.ago.to_date)
    spend(90_000, on: 2.months.ago.to_date, type: debt_type)

    query = described_class.new(space: space, period: Analyses::Period.new("twelve_months"))
    expect(query.units.size).to eq(12)
    expect(query.units.sum(&:amount)).to eq(40_000)
    expect(query.units).to be_none(&:future)
  end
end
