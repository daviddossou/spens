# frozen_string_literal: true

module Analyses
  # Block 1 of the Analyses page: what was CONSUMED over the period, read three
  # ways (vs the named past, vs the plan at today's prorata, essential/plaisir),
  # plus the moved money (loans, repayments, transfers) — out of the totals but
  # never hidden.
  class SpendingQuery
    CONSUMED = %w[expense].freeze
    MOVED = %w[transfer transfer_out debt_in debt_out].freeze
    SMALL_BASE = 10_000

    def initialize(space:, period:)
      @space = space
      @period = period
    end

    def spent_total
      @spent_total ||= abs_sum(CONSUMED, @period.range)
    end

    def moved_total
      @moved_total ||= abs_sum(MOVED, @period.range)
    end

    # nil → nothing to say; {monthly_average:} → 12 months without enough history;
    # {no_data: true} → less than 7 days of data to face; else the named delta.
    def comparison
      return @comparison if defined?(@comparison)

      @comparison = build_comparison
    end

    # Month: prorata reading. Twelve months: "N months inside their plan".
    # Custom: aggregate only when the range hugs whole months.
    def plan
      return @plan if defined?(@plan)

      @plan =
        if @period.month? then month_plan(@period.range.begin)
        elsif @period.twelve_months? then months_plan
        elsif @period.whole_months? then aggregate_plan
        end
    end

    def offplan_total
      return spent_total unless plan && plan[:spent_on_plan]

      (spent_total - plan[:spent_on_plan]).round(2)
    end

    # Split of the PLANNED spend by the budget line's flag; off-plan is excluded
    # and flagged from 10% of the total so the share is never over-read.
    def essential_split
      return nil unless plan && plan[:spent_on_plan].to_f.positive?

      essential = plan[:essential_spent]
      plaisir = (plan[:spent_on_plan] - essential).round(2)
      {
        essential: essential, plaisir: plaisir,
        pct_essential: (essential / plan[:spent_on_plan] * 100).round,
        offplan_noteworthy: spent_total.positive? && offplan_total / spent_total >= 0.10
      }
    end

    PlanRow = Data.define(:entry, :name, :spent, :planned, :prorated, :gap)
    OffplanRow = Data.define(:name, :spent, :other)

    # Overrun = spent beyond the plan PRORATED to today (never the full plan
    # mid-month), sorted by that gap. Single-month periods only.
    def overruns
      plan_rows.select { |r| r.gap.positive? }.sort_by { |r| -r.gap }
    end

    def within_plan
      plan_rows.reject { |r| r.gap.positive? }.sort_by { |r| -r.spent }
    end

    # Expense categories with spend but no budget line; "Autre" reads as
    # uncategorised (its exit is reclassifying, not budgeting).
    def offplan_categories
      return [] unless @period.single_month?

      planned_ids = plan_rows.flat_map { |r| r.entry.transaction_type&.subtree_ids }.compact
      other_names = %w[other_expense].map { |k| TransactionTaxonomy.name(k, I18n.locale) }

      spent_by_parent_type.filter_map do |(type_id, name), amount|
        next if planned_ids.include?(type_id)

        OffplanRow.new(name: name, spent: amount.round(2), other: other_names.include?(name))
      end.sort_by { |r| -r.spent }
    end

    private

    def plan_rows
      return [] unless @period.single_month? && plan

      @plan_rows ||= begin
        month = @period.months.first
        actuals = Budgets::ActualsQuery.new(space: @space, month: month)
        ratio = @period.month? ? @period.days_elapsed.to_f / @period.days_total : 1.0
        month_entries(month).map do |entry|
          spent = actuals.for_entry(entry)
          prorated = (entry.planned_amount.to_f * ratio).round(2)
          PlanRow.new(entry: entry, name: entry.display_name, spent: spent,
                      planned: entry.planned_amount.to_f, prorated: prorated,
                      gap: (spent - prorated).round(2))
        end
      end
    end

    def month_entries(month)
      @space.budget_entries.for_month(month).expense.includes(:budget_item, transaction_type: :children)
    end

    def spent_by_parent_type
      @space.transactions.joins(:transaction_type)
            .where(transaction_types: { kind: "expense" }, transaction_date: @period.range)
            .joins("LEFT JOIN transaction_types parents ON parents.id = transaction_types.parent_id")
            .group(Arel.sql("COALESCE(parents.id, transaction_types.id)"),
                   Arel.sql("COALESCE(parents.name, transaction_types.name)"))
            .sum(Arel.sql("ABS(transactions.amount)"))
    end

    def abs_sum(kinds, range)
      @space.transactions.joins(:transaction_type)
            .where(transaction_types: { kind: kinds }, transaction_date: range)
            .sum("ABS(transactions.amount)").to_f.round(2)
    end

    def build_comparison
      range = comparison_window
      return { monthly_average: (spent_total / 12).round } if range == :average
      return nil if range.nil?

      first = @space.transactions.minimum(:transaction_date)
      return { no_data: true } if first.nil? || ([ range.end, Date.current ].min - [ range.begin, first ].max).to_i + 1 < 7

      previous = abs_sum(CONSUMED, range)
      return { no_data: true } if previous.zero?

      delta(previous, range)
    end

    def comparison_window
      return @period.comparison_range unless @period.twelve_months?

      first = @space.transactions.minimum(:transaction_date)
      full_history = first && first <= (@period.range.begin << 12)
      full_history ? (@period.range.begin << 12)..(@period.range.begin - 1) : :average
    end

    def delta(previous, range)
      base = { previous: previous, range: range }
      if previous < SMALL_BASE
        base.merge(amount: (spent_total - previous).round)
      else
        base.merge(percent: ((spent_total - previous) / previous * 100).round)
      end
    end

    def month_plan(month)
      Budgets::EnsureEntriesService.new(space: @space, month: month).call
      entries = @space.budget_entries.for_month(month).expense.includes(:budget_item, transaction_type: :children)
      return nil if entries.empty?

      actuals = Budgets::ActualsQuery.new(space: @space, month: month)
      spent_by_entry = entries.index_with { |e| actuals.for_entry(e) }

      {
        planned: entries.sum(&:planned_amount).to_f.round(2),
        spent_on_plan: spent_by_entry.values.sum.round(2),
        essential_spent: spent_by_entry.sum { |e, v| e.budget_item.essential ? v : 0 }.round(2),
        prorata_ratio: @period.days_elapsed.to_f / @period.days_total,
        categories_with_plan: entries.size,
        categories_total: categories_total
      }
    end

    # One light pass per month; a month that was never materialized has no
    # entries and simply doesn't count as "in plan".
    def months_plan
      readings = @period.months.filter_map { |m| month_within_plan?(m) }
      { months_ok: readings.count(true), months_total: @period.months.size }
    end

    def month_within_plan?(month)
      entries = @space.budget_entries.for_month(month).expense.includes(:budget_item, transaction_type: :children)
      return nil if entries.empty?

      actuals = Budgets::ActualsQuery.new(space: @space, month: month)
      entries.sum { |e| actuals.for_entry(e) } <= entries.sum(&:planned_amount).to_f
    end

    def aggregate_plan
      months = @period.months
      planned = spent = essential = 0.0
      with_plan = 0
      months.each do |m|
        entries = @space.budget_entries.for_month(m).expense.includes(:budget_item, transaction_type: :children)
        next if entries.empty?

        actuals = Budgets::ActualsQuery.new(space: @space, month: m)
        by_entry = entries.index_with { |e| actuals.for_entry(e) }
        planned += entries.sum(&:planned_amount).to_f
        spent += by_entry.values.sum
        essential += by_entry.sum { |e, v| e.budget_item.essential ? v : 0 }
        with_plan += entries.size
      end
      return nil if planned.zero?

      { planned: planned.round(2), spent_on_plan: spent.round(2), essential_spent: essential.round(2),
        prorata_ratio: @period.days_elapsed.to_f / @period.days_total,
        categories_with_plan: with_plan, categories_total: categories_total }
    end

    def categories_total
      @space.transactions.joins(:transaction_type)
            .where(transaction_types: { kind: "expense" }, transaction_date: @period.range)
            .joins("LEFT JOIN transaction_types parents ON parents.id = transaction_types.parent_id")
            .distinct.count("COALESCE(parents.id, transaction_types.id)")
    end
  end
end
