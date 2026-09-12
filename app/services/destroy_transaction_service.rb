# frozen_string_literal: true

# Reverses a transaction's balance effect, then destroys it.
class DestroyTransactionService
  def initialize(transaction)
    @transaction = transaction
  end

  def call
    attempt = QuickEntryAttempt.find_by(transaction_id: @transaction.id)

    ActiveRecord::Base.transaction do
      TransactionLedger.reverse(TransactionLedger.snapshot(@transaction))
      attempt&.update!(outcome: "deleted")
      @transaction.destroy!
    end

    Analytics.track_quick_entry_resolved(attempt) if attempt
    @transaction
  end
end
