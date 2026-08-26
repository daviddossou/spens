# frozen_string_literal: true

# Closes a debt that's no longer expected — a receivable that won't come back,
# or a debt the other party forgave. Records a neutral write-off transaction (so
# the event stays in history and the feed) and flips the debt to written_off, so
# it drops out of the "owed to me" / "I owe" totals without being deleted.
class WriteOffDebtService
  def initialize(debt, user: nil)
    @debt = debt
    @user = user
  end

  def call
    return false unless @debt.ongoing? && @debt.remaining_balance.positive?

    ActiveRecord::Base.transaction do
      record_write_off
      @debt.update!(status: "written_off")
    end
    true
  rescue StandardError => e
    Rails.logger.error "WriteOffDebtService error: #{e.message}\n#{e.backtrace.join("\n")}"
    false
  end

  private

  def record_write_off
    form = TransactionForm.new(
      @debt.space,
      kind: "debt_writeoff",
      debt_id: @debt.id,
      amount: @debt.remaining_balance,
      transaction_date: Date.current
    )
    form.user = @user
    form.submit

    raise StandardError, form.errors.full_messages.join(", ") unless form.errors.empty?
  end
end
