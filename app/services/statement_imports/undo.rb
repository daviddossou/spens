# frozen_string_literal: true

module StatementImports
  # "Annuler" on the toast (39d): the whole import goes, every transaction it created reversed
  # through the usual service so balances and debts come back.
  class Undo
    WINDOW = 15.minutes

    def self.call(import)
      return false unless import.saved? && import.saved_at > WINDOW.ago

      ActiveRecord::Base.transaction do
        import.transactions.find_each { DestroyTransactionService.new(_1).call }
        import.lines.where(decision: "accepted").update_all(decision: "pending") # rubocop:disable Rails/SkipsModelValidations
        import.update!(status: "undone", undone_at: Time.current)
      end
      true
    end
  end
end
