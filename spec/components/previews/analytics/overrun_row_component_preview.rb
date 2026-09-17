# frozen_string_literal: true

require "ostruct"
require_relative "preview_money"

module Analytics
  # @label Overrun row
  class OverrunRowComponentPreview < ViewComponent::Preview
    include Analytics::PreviewMoney

    # Ahead of the prorated plan, still under the full plan
    def default
      render with_money(Analytics::OverrunRowComponent.new(row: row(spent: 60_000.0, planned: 100_000.0, prorated: 50_000.0)))
    end

    # Past the full plan: the bar is full
    def over_full_plan
      render with_money(Analytics::OverrunRowComponent.new(row: row(spent: 130_000.0, planned: 100_000.0, prorated: 50_000.0)))
    end

    # Single-transaction line: prorated is the full plan, no tick
    def single_transaction
      render with_money(Analytics::OverrunRowComponent.new(row: row(name: "Rent", spent: 90_000.0, planned: 80_000.0, prorated: 80_000.0, single: true)))
    end

    private

    def row(name: "Food", spent:, planned:, prorated:, single: false)
      gap = spent - prorated
      Analyses::SpendingQuery::PlanRow.new(
        entry: OpenStruct.new(id: "preview-entry"), name: name, spent: spent, planned: planned,
        prorated: prorated, gap: gap, single: single, rel_gap: gap / planned
      )
    end
  end
end
