# frozen_string_literal: true

# Posts a transaction's side-effects on account balance and debt totals.
# Invoked explicitly by the create/update/destroy services (incremental, O(1)):
# an edit reverses the old snapshot and applies the new one.
class TransactionLedger
  # `amount` is the SIGNED stored amount.
  Effect = Struct.new(:account, :amount, :debt, :type, keyword_init: true)

  class << self
    # Capture BEFORE mutating the row to get the "old" effect to reverse.
    def snapshot(transaction)
      Effect.new(
        account: transaction.account,
        amount: transaction.amount.to_f,
        debt: transaction.debt,
        type: transaction.transaction_type
      )
    end

    def apply(effect)
      post(effect, +1)
    end

    def reverse(effect)
      post(effect, -1)
    end

    private

    def post(effect, sign)
      adjust_account_balance(effect.account, effect.amount * sign)
      adjust_debt_total(effect.debt, effect.type, effect.amount, sign)
    end

    def adjust_account_balance(account, delta)
      return unless account

      account.balance = (account.balance || 0.0) + delta
      account.save!
    end

    # Assignment + save! so RoundsMoney's before_save fires (increment! bypasses it).
    def adjust_debt_total(debt, type, amount, sign)
      return unless debt && type

      is_increase = (debt.lent? && type.debt_out?) || (debt.borrowed? && type.debt_in?)
      attribute = is_increase ? :total_lent : :total_reimbursed
      debt[attribute] = (debt[attribute] || 0.0) + (amount.abs * sign)
      debt.save!
    end
  end
end
