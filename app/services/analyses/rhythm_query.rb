# frozen_string_literal: true

module Analyses
  # The spending rhythm: one bar per unit (day/week/month per the range), the
  # future grey rather than absent, and the biggest unit named with its top
  # category. Consumed money only.
  class RhythmQuery
    Unit = Data.define(:starts_on, :amount, :future)

    def initialize(space:, period:)
      @space = space
      @period = period
    end

    def units
      @units ||= build_units
    end

    def biggest
      units.reject(&:future).max_by(&:amount)&.then { |u| u.amount.positive? ? u : nil }
    end

    def biggest_category
      unit = biggest or return nil

      scope = expense_scope(unit.starts_on..unit_end(unit.starts_on))
      CategorySpendQuery.new(scope).call.first&.first
    end

    private

    def build_units
      sums = expense_scope(@period.range)
             .group(Arel.sql(truncation))
             .sum(Arel.sql("ABS(transactions.amount)"))
             .transform_keys(&:to_date)

      each_unit_start.map do |start|
        Unit.new(starts_on: start, amount: sums[start].to_f.round(2), future: start > Date.current)
      end
    end

    def truncation
      "DATE_TRUNC('#{@period.granularity}', transactions.transaction_date)::date"
    end

    def each_unit_start
      step = { day: 1, week: 7 }[@period.granularity]
      first = first_unit_start
      return (first..@period.range.end).step(step).map(&:to_date) if step

      @period.months
    end

    # Postgres weeks are ISO (Monday); align the ruby side with it.
    def first_unit_start
      start = @period.range.begin
      @period.granularity == :week ? start.beginning_of_week : start
    end

    def unit_end(start)
      case @period.granularity
      when :day then start
      when :week then start + 6
      else start.end_of_month
      end
    end

    def expense_scope(range)
      @space.transactions.joins(:transaction_type)
            .where(transaction_types: { kind: "expense" }, transaction_date: range)
    end
  end
end
