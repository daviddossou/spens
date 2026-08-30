# frozen_string_literal: true

module QuickEntry
  # Runs the learning off the request path: nothing here is needed to create the transaction,
  # so it happens in the background after the user already has their result.
  #
  # - NoteLearner: the human note → the space's personal vocabulary (+ a global candidate).
  # - AiAssistLearner: when Haiku rescued the entry, its guess becomes candidate vocabulary so
  #   the rules handle the next one AI-free.
  # - CorrectionLearner: when the user completed a prefilled form or edited a quick-entry
  #   transaction, their choices correct the parse (no-ops without a linked attempt).
  class LearnTransactionJob < ApplicationJob
    queue_as :default

    def perform(transaction_id, ai_assist: false, correction: false)
      transaction = Transaction.find_by(id: transaction_id) or return

      NoteLearner.learn(transaction)
      CorrectionLearner.learn(transaction) if correction

      if ai_assist && (attempt = QuickEntryAttempt.find_by(transaction_id: transaction_id))&.ai_used?
        AiAssistLearner.learn(attempt)
      end
    end
  end
end
