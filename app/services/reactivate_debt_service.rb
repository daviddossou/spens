# frozen_string_literal: true

# Reverses a write-off: a debt you'd stopped counting on comes back (the person
# paid after all, or you changed your mind). Removes the neutral write-off event
# and flips the debt to ongoing for its remaining balance, re-establishing any
# repayment plan the deadline implies.
class ReactivateDebtService
  def initialize(debt, user: nil)
    @debt = debt
    @user = user
  end

  def call
    return false unless @debt.written_off?

    ActiveRecord::Base.transaction do
      @debt.transactions.joins(:transaction_type)
           .where(transaction_types: { kind: "debt_writeoff" }).destroy_all
      @debt.update!(status: "ongoing")
      Budgets::SyncDebtPlanService.call(@debt.reload)
    end
    true
  rescue StandardError => e
    Rails.logger.error "ReactivateDebtService error: #{e.message}\n#{e.backtrace.join("\n")}"
    false
  end
end
