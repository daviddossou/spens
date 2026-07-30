# frozen_string_literal: true

module Budgets
  # Lazily materializes a month's budget entries from the space's active budget
  # items. Idempotent: safe to call on every page view; the unique index on
  # [space, budget_item, month] guards against concurrent duplicates.
  #
  # Rollover items also carry last occurrence's unspent remainder into this
  # month's planned amount. The carry is recomputed on every call while the
  # month is current or future (late edits to last month still land), then
  # freezes once the month is past.
  class EnsureEntriesService
    def initialize(space:, month:)
      @space = space
      @month = month.beginning_of_month
    end

    def call
      @space.budget_items.active.includes(:transaction_type, :debt).find_each do |item|
        # A settled debt has nothing left to plan: retire its line.
        if item.debt_kind? && item.debt&.paid?
          item.update!(active: false)
          next
        end

        next unless item.occurs_in?(@month)

        entry = @space.budget_entries.find_by(budget_item_id: item.id, month: @month)
        entry ||= begin
          @space.budget_entries.create_or_find_by!(budget_item_id: item.id, month: @month) do |e|
            e.transaction_type = item.transaction_type
            e.kind = item.kind
            e.planned_amount = item.planned_amount_for(@month)
          end
        rescue ActiveRecord::RecordInvalid
          # A concurrent request materialized this entry between our miss and the create.
          @space.budget_entries.find_by(budget_item_id: item.id, month: @month)
        end
        next if entry.nil?

        apply_rollover(item, entry)
      end
    end

    private

    def apply_rollover(item, entry)
      return unless item.rollover? && item.kind == "expense"
      return if @month < Date.current.beginning_of_month

      carried = carryover_for(item)
      delta = carried - entry.carried_amount
      return if delta.zero?

      # Adjust by the delta so a manual override of this month's planned
      # amount survives the recomputation.
      entry.update!(carried_amount: carried, planned_amount: entry.planned_amount + delta)
    end

    # Unspent remainder of the item's most recent entry before this month.
    # Only a positive remainder carries: overspending never shrinks next month.
    def carryover_for(item)
      previous = @space.budget_entries
                       .where(budget_item_id: item.id)
                       .where(month: ...@month)
                       .order(month: :desc)
                       .first
      return 0 if previous.nil?

      actual = actuals_for(previous.month).for_entry(previous)
      [ previous.planned_amount - actual, 0 ].max.round(2)
    end

    def actuals_for(month)
      @actuals_by_month ||= {}
      @actuals_by_month[month] ||= ActualsQuery.new(space: @space, month: month)
    end
  end
end
