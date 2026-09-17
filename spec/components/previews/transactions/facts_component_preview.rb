# frozen_string_literal: true

module Transactions
  # @label Movement facts
  class FactsComponentPreview < ViewComponent::Preview
    include PreviewSpace

    # An expense: every fact opens its selector
    def default
      transaction = build_transaction(kind: "expense", category: "Groceries", amount: -12_500)
      render with_helpers(Transactions::FactsComponent.new(transaction: transaction, editable: true))
    end

    # An expense with no account yet
    def without_account
      transaction = build_transaction(kind: "expense", category: "Groceries", amount: -12_500, account: nil)
      render with_helpers(Transactions::FactsComponent.new(transaction: transaction, editable: true))
    end

    # A debt movement: category fixed, account links to its page, plus the related debt
    def debt
      debt = Debt.new(id: SecureRandom.uuid, name: "Georges", direction: "lent", total_lent: 50_000, space: preview_space)
      transaction = build_transaction(kind: "debt_out", category: "Loan", amount: -50_000, debt: debt)
      render with_helpers(Transactions::FactsComponent.new(transaction: transaction, editable: false))
    end

    # A transfer leg: nothing to reassign but the date
    def transfer
      transaction = build_transaction(kind: "transfer_out", category: "Transfer", amount: -20_000)
      render with_helpers(Transactions::FactsComponent.new(transaction: transaction, editable: false))
    end
  end
end
