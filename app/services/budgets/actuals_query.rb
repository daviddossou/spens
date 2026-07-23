# frozen_string_literal: true

module Budgets
  # Actual money moved for each budget entry in one month. Every kind sums all
  # matching transactions of the month (several groceries runs, several partial
  # debt repayments…) — fulfillment is a threshold, never a single transaction.
  class ActualsQuery
    def initialize(space:, month:)
      @space = space
      @month = month.beginning_of_month
    end

    def for_entry(entry)
      item = entry.budget_item

      case entry.kind
      when "transfer" then transfer_actual(item)
      when "debt_in", "debt_out" then debt_actual(item, entry.kind)
      else category_actual(item.transaction_type)
      end
    end

    private

    # Category spend, subtree included (a budget on "Housing" counts spend
    # recorded on its subcategories too).
    def category_actual(transaction_type)
      return 0 if transaction_type.nil?

      category_sums.values_at(*transaction_type.subtree_ids).compact.sum.abs.round(2)
    end

    def category_sums
      @category_sums ||= month_scope.group(:transaction_type_id).sum(:amount)
    end

    # Sum of the month's transfer_out legs leaving from_account whose partner
    # leg landed on to_account.
    def transfer_actual(item)
      return 0 if item.from_account_id.blank? || item.to_account_id.blank?

      month_scope
        .joins(:transaction_type)
        .where(transaction_types: { kind: "transfer_out" }, account_id: item.from_account_id)
        .where.not(transfer_group_id: nil)
        .where(transfer_group_id: partner_groups_into(item.to_account_id))
        .sum(:amount).abs.round(2)
    end

    def partner_groups_into(account_id)
      @space.transactions
            .joins(:transaction_type)
            .where(transaction_date: @month.all_month)
            .where(transaction_types: { kind: "transfer_in" }, account_id: account_id)
            .select(:transfer_group_id)
    end

    # Sum of this debt's movements in the budgeted direction.
    def debt_actual(item, kind)
      return 0 if item.debt_id.blank?

      month_scope
        .joins(:transaction_type)
        .where(debt_id: item.debt_id, transaction_types: { kind: kind })
        .sum(:amount).abs.round(2)
    end

    def month_scope
      @space.transactions.where(transaction_date: @month.all_month, fee_parent_id: nil)
    end
  end
end
