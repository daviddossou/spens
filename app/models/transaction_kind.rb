# frozen_string_literal: true

# Central classification of transaction-type kinds, shared across the form,
# services, ledger, and helpers.
module TransactionKind
  TRANSFER = %w[transfer transfer_in transfer_out].freeze
  DEBT = %w[debt_in debt_out].freeze
  MONEY_OUT = %w[expense transfer_out debt_out].freeze
  MONEY_IN = %w[income transfer_in debt_in].freeze
  FEE_APPLICABLE = %w[expense transfer debt_out].freeze
  # Reconciliations, not real in/out flows: excluded from money-in/out and day
  # totals, and shown in grey. A write-off and a compensation move no cash; an
  # adjustment and an initial balance move a balance but are a reconciliation.
  NEUTRAL = %w[debt_writeoff compensation adjustment initial_balance].freeze

  module_function

  def transfer?(kind) = TRANSFER.include?(kind)
  def debt?(kind) = DEBT.include?(kind)
  def money_out?(kind) = MONEY_OUT.include?(kind)
  def money_in?(kind) = MONEY_IN.include?(kind)
  def fee_applicable?(kind) = FEE_APPLICABLE.include?(kind)
  def neutral?(kind) = NEUTRAL.include?(kind)
end
