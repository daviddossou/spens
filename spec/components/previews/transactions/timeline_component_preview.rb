# frozen_string_literal: true

module Transactions
  # @label Timeline
  class TimelineComponentPreview < ViewComponent::Preview
    include PreviewSpace

    # Several days as on the dashboard
    def default
      render with_helpers(Transactions::TimelineComponent.new(grouped_transactions: grouped))
    end

    # On an account page: transfers count in the day totals
    def account_scope
      render with_helpers(Transactions::TimelineComponent.new(grouped_transactions: grouped, day_total_scope: :account))
    end

    private

    def grouped
      account = build_account
      today = Date.current
      {
        today => [
          build_transaction(kind: "expense", category: "Groceries", amount: -12_500, account: account, note: "Carrefour"),
          build_transaction(kind: "transfer_out", category: "Transfer", amount: -50_000, account: account)
        ],
        today - 1 => [
          build_transaction(kind: "income", category: "Salary", amount: 300_000, account: account, date: today - 1)
        ],
        today - 3 => [
          build_transaction(kind: "expense", category: "Transport", amount: -1_500, account: account, date: today - 3, label: "Zem"),
          build_transaction(kind: "expense", category: "Restaurant", amount: -8_000, account: account, date: today - 3)
        ]
      }
    end
  end
end
