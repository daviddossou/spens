# frozen_string_literal: true

require "ostruct"
require_relative "preview_money"

module Analytics
  # @label Spending summary
  class SpendingSummaryComponentPreview < ViewComponent::Preview
    include Analytics::PreviewMoney

    # Mid-month, up on last month, above the planned pace, with the split
    def default
      render summary(plan: { planned: 250_000.0, spent_on_plan: 165_000.0 }, prorated: 140_000.0,
                     comparison: { percent: 12, previous: 145_000.0, range: last_month_range })
    end

    # Under the planned pace, down on last month
    def under_pace
      render summary(plan: { planned: 250_000.0, spent_on_plan: 110_000.0 }, prorated: 140_000.0,
                     comparison: { percent: -9, previous: 178_000.0, range: last_month_range })
    end

    # The plan is exceeded: red row, full bar
    def over_plan
      render summary(spent_total: 290_000.0, plan: { planned: 250_000.0, spent_on_plan: 270_000.0 }, prorated: 140_000.0,
                     comparison: { percent: 40, previous: 200_000.0, range: last_month_range })
    end

    # The period is over: the tick goes, the verdict closes
    def month_closed
      render summary(plan: { planned: 250_000.0, spent_on_plan: 210_000.0 }, prorated: 250_000.0,
                     comparison: { amount: 6_000, previous: 4_000.0, range: last_month_range })
    end

    # Twelve months: the plan is a count of months, the comparison an average
    def twelve_months
      render summary(kind: "twelve_months", spent_total: 2_400_000.0, plan: { months_ok: 9, months_total: 12 },
                     comparison: { monthly_average: 200_000 }, split: nil)
    end

    # Custom range, no plan, loans went out
    def custom_range_with_loans
      render summary(kind: "custom", start_date: Date.current - 20, end_date: Date.current - 5, plan: nil, split: nil,
                     comparison: { percent: 3, previous: 90_000.0, range: (Date.current - 36)..(Date.current - 21) }, lent_total: 25_000.0)
    end

    # No history to compare against, nothing planned yet
    def bare
      render summary(plan: nil, split: nil, comparison: { no_data: true })
    end

    private

    def summary(kind: "month", start_date: nil, end_date: nil, spent_total: 180_000.0, plan:, prorated: 0.0, comparison:,
                split: default_split, lent_total: 0.0, overruns: [])
      period = Analyses::Period.new(kind, start_date: start_date, end_date: end_date)
      spending = OpenStruct.new(spent_total: spent_total, prorated_plan_total: prorated, plan: plan,
                                overruns: overruns, lent_total: lent_total)
      with_money(Analytics::SpendingSummaryComponent.new(period: period, spending: spending, range: period.range,
                                                         comparison: comparison, plan: plan, split: split))
    end

    def default_split
      { essential: 110_000.0, plaisir: 55_000.0, unclassified: 15_000.0, pct_essential: 61 }
    end

    def last_month_range
      bom = Date.current.beginning_of_month << 1
      bom..[ bom + Date.current.day - 1, bom.end_of_month ].min
    end
  end
end
