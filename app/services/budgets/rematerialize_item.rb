# frozen_string_literal: true

module Budgets
  # Keep a budget item's current and future entries in line with its (possibly
  # changed) rule; past months are history and stay untouched. Entries that no
  # longer occur — e.g. beyond a freshly set ends_on — are pruned.
  class RematerializeItem
    def self.call(item) = new(item).call

    def initialize(item)
      @item = item
      @space = item.space
    end

    def call
      current_month = Date.current.beginning_of_month

      @item.budget_entries.where(month: current_month..).find_each do |entry|
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
