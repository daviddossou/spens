# frozen_string_literal: true

# Offsets a two-way relation: what the person owes you cancels an equal slice of
# what you owe them (or vice-versa). Writes a dated repayment on each side — no
# cash moves, nothing is deleted — so the smaller debt clears and the larger drops
# to the net. Idempotent-safe: does nothing unless money flows both ways.
class CompensateDebtsService
  def initialize(relation, user: nil)
    @relation = relation
    @user = user
  end

  def call
    amount = @relation.offsettable
    return false unless @relation.two_way? && amount.positive?

    ActiveRecord::Base.transaction do
      # They "repay" the slice on what they owe you; you "repay" it on what you owe.
      # Both legs are the neutral "compensation" kind: no cash moves, but each
      # still reduces its debt's remaining balance (via total_reimbursed).
      record(@relation.lent, "compensation", amount)
      record(@relation.borrowed, "compensation", amount)
    end
    true
  rescue StandardError => e
    Rails.logger.error "CompensateDebtsService error: #{e.message}\n#{e.backtrace.join("\n")}"
    false
  end

  private

  def record(debt, kind, amount)
    form = TransactionForm.new(
      debt.space,
      kind: kind,
      debt_id: debt.id,
      amount: amount,
      transaction_date: Date.current,
      description: I18n.t("debts.compensate.movement", name: @relation.name)
    )
    form.user = @user
    form.submit

    raise StandardError, form.errors.full_messages.join(", ") unless form.errors.empty?
  end
end
