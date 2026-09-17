# frozen_string_literal: true

module Transactions
  # @label Movement hero
  class MovementHeroComponentPreview < ViewComponent::Preview
    include PreviewSpace

    # An expense with a note
    def default
      hero(build_transaction(kind: "expense", category: "Groceries", amount: -12_500, note: "Carrefour, weekly run"))
    end

    # An income
    def income
      hero(build_transaction(kind: "income", category: "Salary", amount: 300_000))
    end

    # A transfer leg
    def transfer
      hero(build_transaction(kind: "transfer_out", category: "Transfer", amount: -50_000))
    end

    # A loan to someone
    def debt
      debt = Debt.new(id: SecureRandom.uuid, name: "Georges", direction: "lent", total_lent: 50_000, space: preview_space)
      hero(build_transaction(kind: "debt_out", category: "Loan", amount: -50_000, debt: debt))
    end

    # An opening balance: muted, no sign
    def neutral
      hero(build_transaction(kind: "initial_balance", category: "Opening balance", amount: 100_000))
    end

    # An adjustment keeps its sign
    def adjustment
      hero(build_transaction(kind: "adjustment", category: "Adjustment", amount: -3_000))
    end

    private

    def hero(transaction)
      helpers = preview_helpers
      row = MovementRow.new(transaction, formatter: ->(amount) { helpers.money(amount.abs) })
      render with_helpers(Transactions::MovementHeroComponent.new(transaction: transaction, row: row))
    end
  end
end
