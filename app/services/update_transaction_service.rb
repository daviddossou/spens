# frozen_string_literal: true

# Updates a single transaction row in place, reversing the old balance effect and
# applying the new (via TransactionLedger). Only the attribute keys present are
# touched: kind, transaction_type_name, account_name, amount, description,
# transaction_date, note, debt, transfer_group_id.
class UpdateTransactionService
  def initialize(transaction:, attributes:)
    @transaction = transaction
    @attributes = attributes
  end

  def call
    ActiveRecord::Base.transaction do
      old = TransactionLedger.snapshot(@transaction)
      @transaction.assign_attributes(resolved_updates)
      @transaction.save!
      TransactionLedger.reverse(old)
      TransactionLedger.apply(TransactionLedger.snapshot(@transaction))
    end

    @transaction
  end

  private

  def resolved_updates
    updates = {}

    updates[:description] = @attributes[:description] if @attributes[:description].present?
    updates[:transaction_date] = @attributes[:transaction_date] if @attributes[:transaction_date].present?
    updates[:note] = @attributes[:note] if @attributes.key?(:note)
    updates[:transfer_group_id] = @attributes[:transfer_group_id] if @attributes.key?(:transfer_group_id)
    updates[:debt] = reuse_if_same(@attributes[:debt], @transaction.debt) if @attributes.key?(:debt)

    if @attributes[:transaction_type_name].present? || @attributes[:kind].present?
      updates[:transaction_type] = resolved_type
    end

    if @attributes[:account_name].present?
      found = FindOrCreateAccountService.new(@transaction.space, @attributes[:account_name]).call
      updates[:account] = reuse_if_same(found, @transaction.account)
    end

    type_for_amount = updates[:transaction_type] || @transaction.transaction_type
    if @attributes[:amount].present? && @attributes[:amount].to_d > 0
      updates[:amount] = NormalizeAmountService.new(amount: @attributes[:amount], transaction_type: type_for_amount).call
    elsif kind_changed?
      # Re-normalize the existing magnitude with the new sign (expense -50 → income +50).
      updates[:amount] = NormalizeAmountService.new(amount: @transaction.amount, transaction_type: type_for_amount).call
    end

    updates
  end

  def resolved_type
    kind = @attributes[:kind].presence || @transaction.transaction_type.kind
    type_name = @attributes[:transaction_type_name].presence || @transaction.transaction_type.name
    found = FindOrCreateTransactionTypeService.new(@transaction.space, type_name, kind).call
    reuse_if_same(found, @transaction.transaction_type)
  end

  def kind_changed?
    @attributes[:kind].present? && @attributes[:kind] != @transaction.transaction_type.kind
  end

  # Reuse the current instance when it's the same DB row, so the ledger's
  # reverse+apply compose on one object instead of double-applying across two.
  def reuse_if_same(found, current)
    return current if found && current && found.id == current.id

    found
  end
end
