# frozen_string_literal: true

module Budgets
  # @label Entry Row
  class EntryRowComponentPreview < ViewComponent::Preview
    # A vital expense part-way through the month
    def in_progress
      render_row(expense_entry, actual: 40_000)
    end

    # Nothing moved yet
    def expected
      render_row(expense_entry, actual: 0)
    end

    # Paid on plan: the green check
    def celebrate
      render_row(expense_entry, actual: 100_000)
    end

    # Spent more than planned
    def over_budget
      render_row(expense_entry(essential: false), actual: 120_000)
    end

    # A hand-set amount for this month only
    def exception
      render_row(expense_entry(planned: 120_000, overridden: true), actual: 30_000)
    end

    # Part of the plan carried over from last month
    def carried_over
      render_row(expense_entry(carried: 5_000), actual: 20_000)
    end

    # Plan mode: only the planned amount
    def plan_mode
      render_row(expense_entry, actual: 0, mode: :plan)
    end

    # A closed month: no link
    def read_only
      render_row(expense_entry(kind: "transfer"), actual: 20_000, read_only: true)
    end

    # A transfer between two accounts
    def transfer
      render_row(expense_entry(kind: "transfer"), actual: 20_000)
    end

    # A lent debt being repaid to you
    def debt_incoming
      render_row(expense_entry(kind: "debt_in"), actual: 4_000)
    end

    # A debt you repay
    def debt_outgoing
      render_row(expense_entry(kind: "debt_out"), actual: 4_000)
    end

    private

    def render_row(entry, actual:, mode: :live, read_only: false)
      render Budgets::EntryRowComponent.new(entry: entry, actual: actual, currency: "XOF", read_only: read_only, mode: mode)
    end

    def expense_entry(kind: "expense", planned: 100_000, essential: true, overridden: false, carried: 0)
      item = BudgetItem.new(id: SecureRandom.uuid, kind: kind, amount: 100_000, frequency: "monthly", essential: essential)
      case kind
      when "transfer"
        item.from_account = Account.new(name: "Bank")
        item.to_account = Account.new(name: "Savings")
      when "debt_in", "debt_out"
        item.debt = Debt.new(name: "Georges")
      else
        item.transaction_type = TransactionType.new(id: SecureRandom.uuid, name: "Rent", kind: kind)
      end
      BudgetEntry.new(id: SecureRandom.uuid, kind: kind, month: Date.current.beginning_of_month, planned_amount: planned,
                      budget_item: item, transaction_type: item.transaction_type, overridden: overridden, carried_amount: carried)
    end
  end
end
