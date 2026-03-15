# frozen_string_literal: true

class UpdateTransactionService
  def initialize(transaction:, attributes:)
    @transaction = transaction
    @attributes = attributes
  end

  def call
    updates = {}

    updates[:description] = @attributes[:description] if @attributes[:description].present?
    updates[:transaction_date] = @attributes[:transaction_date] if @attributes[:transaction_date].present?

    if @attributes[:transaction_type_name].present?
      kind = @transaction.transaction_type.kind
      updates[:transaction_type] = FindOrCreateTransactionTypeService.new(
        @transaction.space, @attributes[:transaction_type_name], kind
      ).call
    end

    if @attributes[:account_name].present?
      updates[:account] = FindOrCreateAccountService.new(
        @transaction.space, @attributes[:account_name]
      ).call
    end

    if @attributes[:amount].present? && @attributes[:amount].to_d > 0
      tt = updates[:transaction_type] || @transaction.transaction_type
      updates[:amount] = NormalizeAmountService.new(amount: @attributes[:amount], transaction_type: tt).call
    end

    @transaction.update!(updates)
    @transaction
  end
end
