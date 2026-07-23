# frozen_string_literal: true

module Budgets
  # Lazily materializes a month's budget entries from the space's active budget
  # items. Idempotent: safe to call on every page view; the unique index on
  # [space, budget_item, month] guards against concurrent duplicates.
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

        begin
          @space.budget_entries.create_or_find_by!(budget_item_id: item.id, month: @month) do |entry|
            entry.transaction_type = item.transaction_type
            entry.kind = item.kind
            entry.planned_amount = item.planned_amount_for(@month)
          end
        rescue ActiveRecord::RecordInvalid
          # A concurrent request already materialized this entry.
          next
        end
      end
    end
  end
end
