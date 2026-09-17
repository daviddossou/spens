# frozen_string_literal: true

require "ostruct"
require_relative "preview_money"

module Analytics
  # @label Budget variance
  class BudgetVarianceComponentPreview < ViewComponent::Preview
    include Analytics::PreviewMoney

    # Two overruns, lines within plan folded, off-plan spend past 10%
    def default
      render component(overruns: overruns.first(2), within: within, offplan: offplan)
    end

    # Five overruns: three shown, two folded
    def many_overruns
      render component(overruns: overruns, within: within.first(1), offplan: [])
    end

    # Everything holds its plan: only the fold
    def all_within_plan
      render component(overruns: [], within: within, offplan: [])
    end

    # Off-plan tail: five categories, two folded into a muted row
    def offplan_tail
      render component(overruns: [], within: [], offplan: offplan + [ offplan_row("Gifts", 9_000.0), offplan_row("Books", 4_000.0) ])
    end

    # Off-plan under a tenth of the total: hidden
    def offplan_negligible
      render component(overruns: overruns.first(1), within: within, offplan: offplan, offplan_total: 8_000.0)
    end

    private

    def component(overruns:, within:, offplan:, offplan_total: offplan.sum(&:spent))
      plan = { categories_with_plan: overruns.size + within.size, categories_total: overruns.size + within.size + offplan.size }
      spending = OpenStruct.new(plan: plan, overruns: overruns, within_plan: within, offplan_categories: offplan,
                                spent_total: 320_000.0, offplan_total: offplan_total)
      with_money(Analytics::BudgetVarianceComponent.new(period: Analyses::Period.new("month"), spending: spending, plan: plan))
    end

    def plan_row(name, spent:, planned:, prorated:, single: false)
      gap = spent - prorated
      Analyses::SpendingQuery::PlanRow.new(
        entry: OpenStruct.new(id: "preview-#{name.parameterize}"), name: name, spent: spent, planned: planned,
        prorated: prorated, gap: gap, single: single, rel_gap: planned.positive? ? gap / planned : 0
      )
    end

    def offplan_row(name, spent, other: false)
      Analyses::SpendingQuery::OffplanRow.new(name: name, spent: spent, other: other)
    end

    def overruns
      [
        plan_row("Food", spent: 68_000.0, planned: 100_000.0, prorated: 55_000.0),
        plan_row("Taxi", spent: 24_000.0, planned: 30_000.0, prorated: 16_500.0),
        plan_row("Phone", spent: 12_000.0, planned: 15_000.0, prorated: 8_250.0),
        plan_row("Eating out", spent: 21_000.0, planned: 25_000.0, prorated: 13_750.0),
        plan_row("Clothes", spent: 15_000.0, planned: 20_000.0, prorated: 11_000.0)
      ]
    end

    def within
      [
        plan_row("Rent", spent: 120_000.0, planned: 120_000.0, prorated: 120_000.0, single: true),
        plan_row("Fuel", spent: 14_000.0, planned: 40_000.0, prorated: 22_000.0),
        plan_row("Electricity", spent: 0.0, planned: 18_000.0, prorated: 9_900.0)
      ]
    end

    def offplan
      [ offplan_row("Pharmacy", 26_000.0), offplan_row("Other", 18_000.0, other: true), offplan_row("Hairdresser", 6_000.0) ]
    end
  end
end
