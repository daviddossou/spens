# frozen_string_literal: true

# Central classification of transaction-type kinds, shared across the form,
# services, ledger, and helpers.
module TransactionKind
  TRANSFER = %w[transfer transfer_in transfer_out].freeze
  DEBT = %w[debt_in debt_out].freeze
  MONEY_OUT = %w[expense transfer_out debt_out].freeze
  MONEY_IN = %w[income transfer_in debt_in].freeze
  FEE_APPLICABLE = %w[expense transfer debt_out].freeze

  module_function

  def transfer?(kind) = TRANSFER.include?(kind)
  def debt?(kind) = DEBT.include?(kind)
  def money_out?(kind) = MONEY_OUT.include?(kind)
  def money_in?(kind) = MONEY_IN.include?(kind)
  def fee_applicable?(kind) = FEE_APPLICABLE.include?(kind)
end
