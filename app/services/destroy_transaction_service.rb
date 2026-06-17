# frozen_string_literal: true

# Reverses a transaction's balance effect, then destroys it.
class DestroyTransactionService
  def initialize(transaction)
    @transaction = transaction
  end

  def call
    ActiveRecord::Base.transaction do
      TransactionLedger.reverse(TransactionLedger.snapshot(@transaction))
      @transaction.destroy!
    end

    @transaction
  end
end
