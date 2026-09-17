# frozen_string_literal: true

module Transactions
  # @label Day group
  class DayGroupComponentPreview < ViewComponent::Preview
    include PreviewSpace

    # A day on the dashboard: transfers stay out of the total
    def default
      render with_helpers(Transactions::DayGroupComponent.new(date: Date.current, transactions: day_transactions))
    end

    # The same day on an account page: transfers move this account, so they count
    def account_scope
      render with_helpers(Transactions::DayGroupComponent.new(date: Date.current, transactions: day_transactions, day_total_scope: :account))
    end

    # A day made only of an opening balance
    def off_totals
      opening = build_transaction(kind: "initial_balance", category: "Opening balance", amount: 100_000)
      render with_helpers(Transactions::DayGroupComponent.new(date: Date.current - 30, transactions: [ opening ]))
    end

    # Inside a category page: short date, signed sum, sub-category first
    def in_category
      account = build_account
      category = build_type("🛒 Food & Groceries", "expense")
      lines = [
        build_transaction(kind: "expense", category: "🛒 Groceries", amount: -12_500, account: account, note: "Carrefour"),
        build_transaction(kind: "expense", category: "🍽️ Restaurant", amount: -8_000, account: account)
      ]
      render with_helpers(Transactions::DayGroupComponent.new(date: Date.current, transactions: lines, category: category, subcategory_hint: true))
    end

    private

    def day_transactions
      account = build_account
      [
        build_transaction(kind: "income", category: "Salary", amount: 300_000, account: account),
        build_transaction(kind: "expense", category: "Groceries", amount: -12_500, account: account, note: "Carrefour"),
        build_transaction(kind: "transfer_out", category: "Transfer", amount: -50_000, account: account)
      ]
    end
  end
end
