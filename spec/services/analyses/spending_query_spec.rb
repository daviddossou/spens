# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analyses::SpendingQuery do
  let(:space) { create(:space) }
  let(:account) { create(:account, space: space) }
  let(:period) { Analyses::Period.new("month") }
  subject(:query) { described_class.new(space: space, period: period) }

  def type(kind, name)
    create(:transaction_type, space: space, kind: kind, name: name)
  end

  def spend(amount, type:, on: Date.current)
    create(:transaction, space: space, account: account, transaction_type: type,
                         amount: -amount, transaction_date: on)
  end

  describe "the three natures" do
    it "only consumption feeds the total; moved money is counted apart" do
      groceries = type("expense", "Courses X")
      debt_out = type("debt_out", "Prêt X")
      transfer_out = type("transfer_out", "Sortant X")

      spend(20_000, type: groceries)
      spend(50_000, type: debt_out)
      spend(30_000, type: transfer_out)

      expect(query.spent_total).to eq(20_000)
      expect(query.moved_total).to eq(80_000)
    end

    it "ignores neutral reconciliations everywhere" do
      create(:transaction, space: space, account: account, amount: 99_000,
                           transaction_type: type("adjustment", "Ajust X"))
      expect(query.spent_total).to eq(0)
      expect(query.moved_total).to eq(0)
    end
  end

  describe "#comparison" do
    let(:groceries) { type("expense", "Courses X") }

    it "names last month cut at the same day, as a percent" do
      create(:transaction, space: space, account: account, transaction_type: groceries,
                          amount: -100_000, transaction_date: 3.months.ago) # old history
      spend(50_000, type: groceries, on: (Date.current << 1).beginning_of_month + 2)
      spend(54_000, type: groceries)

      expect(query.comparison[:previous]).to eq(50_000)
      expect(query.comparison[:percent]).to eq(8)
    end

    it "gives the gap in FCFA, not a percent, on a small base" do
      create(:transaction, space: space, account: account, transaction_type: groceries,
                          amount: -5_000, transaction_date: 3.months.ago)
      spend(5_000, type: groceries, on: (Date.current << 1).beginning_of_month + 1)
      spend(8_000, type: groceries)

      expect(query.comparison[:amount]).to eq(3_000)
      expect(query.comparison).not_to have_key(:percent)
    end

    it "declines to compare on fewer than 7 days of facing data" do
      spend(8_000, type: groceries)
      expect(query.comparison).to eq(no_data: true)
    end

    it "falls back to a monthly average for 12 months without 24 months of history" do
      twelve = described_class.new(space: space, period: Analyses::Period.new("twelve_months"))
      spend(120_000, type: groceries, on: 2.months.ago.to_date)
      expect(twelve.comparison).to eq(monthly_average: 10_000)
    end
  end

  describe "#plan (month)" do
    it "reads the prorata, the on-plan spend and the essential split" do
      groceries = type("expense", "Courses X")
      outings = type("expense", "Sorties X")
      item_v = create(:budget_item, space: space, transaction_type: groceries, amount: 60_000, essential: true)
      item_p = create(:budget_item, space: space, transaction_type: outings, amount: 15_000, essential: false)
      create(:budget_entry, space: space, budget_item: item_v, transaction_type: groceries, planned_amount: 60_000)
      create(:budget_entry, space: space, budget_item: item_p, transaction_type: outings, planned_amount: 15_000)

      spend(84_000, type: groceries)
      spend(10_000, type: outings)
      spend(2_000, type: type("expense", "Loisirs X")) # off-plan

      expect(query.plan[:planned]).to eq(75_000)
      expect(query.plan[:spent_on_plan]).to eq(94_000)
      expect(query.plan[:categories_with_plan]).to eq(2)
      expect(query.plan[:categories_total]).to eq(3)
      expect(query.offplan_total).to eq(2_000)

      split = query.essential_split
      expect(split[:essential]).to eq(84_000)
      expect(split[:plaisir]).to eq(10_000)
      expect(split[:pct_essential]).to eq(89)
    end

    it "is nil without any budget line" do
      spend(5_000, type: type("expense", "Courses X"))
      expect(query.plan).to be_nil
      expect(query.essential_split).to be_nil
    end
  end
end
