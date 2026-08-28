# frozen_string_literal: true

module Budgets
  # Keep a budget item's current and future entries in line with its (possibly
  # changed) rule; past months are history and stay untouched. Entries that no
  # longer occur — e.g. beyond a freshly set ends_on — are pruned.
  class RematerializeItem
    def self.call(item, from_month: nil) = new(item, from_month: from_month).call

    def initialize(item, from_month: nil)
      @item = item
      @space = item.space
      @from_month = from_month
    end

    def call
      current_month = Date.current.beginning_of_month
      # A rule change takes effect from the month it was made on (default: now).
      # Months before that stay frozen as history.
      boundary = [ @from_month&.beginning_of_month, current_month ].compact.max

      @item.budget_entries.where(month: boundary..).find_each do |entry|
        # A month set by hand keeps its exception — the rule doesn't overwrite it.
        next if entry.overridden?

        if @item.active? && @item.occurs_in?(entry.month)
          entry.update!(transaction_type: @item.transaction_type, kind: @item.kind,
                        planned_amount: @item.planned_amount_for(entry.month))
        else
          entry.destroy!
        end
      end

      EnsureEntriesService.new(space: @space, month: current_month).call
    end
  end
end
