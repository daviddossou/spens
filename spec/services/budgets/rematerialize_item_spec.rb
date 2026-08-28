# frozen_string_literal: true

require "rails_helper"

RSpec.describe Budgets::RematerializeItem do
  let(:space) { create(:space) }

  it "leaves a hand-set (overridden) month alone when the rule changes" do
    travel_to Date.new(2026, 1, 10) do
      item = create(:budget_item, space: space, kind: "expense", amount: 100_000,
                                  starts_on: Date.new(2026, 1, 1))
      overridden = create(:budget_entry, space: space, budget_item: item, kind: "expense",
                                         month: Date.new(2026, 3, 1), planned_amount: 150_000,
                                         overridden: true, overridden_at: Time.current)
      following = create(:budget_entry, space: space, budget_item: item, kind: "expense",
                                        month: Date.new(2026, 4, 1), planned_amount: 100_000)

      item.update!(amount: 120_000)
      described_class.call(item)

      expect(overridden.reload.planned_amount).to eq(150_000) # exception kept
      expect(following.reload.planned_amount).to eq(120_000)  # rule applied
    end
  end

  it "freezes months before the effective month" do
    travel_to Date.new(2026, 1, 10) do
      item = create(:budget_item, space: space, kind: "expense", amount: 100_000,
                                  starts_on: Date.new(2026, 1, 1))
      jan = create(:budget_entry, space: space, budget_item: item, kind: "expense",
                                  month: Date.new(2026, 1, 1), planned_amount: 100_000)
      march = create(:budget_entry, space: space, budget_item: item, kind: "expense",
                                    month: Date.new(2026, 3, 1), planned_amount: 100_000)

      item.update!(amount: 120_000)
      described_class.call(item, from_month: Date.new(2026, 3, 1))

      expect(jan.reload.planned_amount).to eq(100_000)   # before effective month: untouched
      expect(march.reload.planned_amount).to eq(120_000) # from effective month: rule applied
    end
  end
end
