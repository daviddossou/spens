# frozen_string_literal: true

class NormalizeAmountService
  def initialize(amount:, transaction_type:)
    @amount = amount
    @transaction_type = transaction_type
  end

  def call
    kind = @transaction_type.kind
    if TransactionKind.money_out?(kind)
      -@amount.to_d.abs
    elsif TransactionKind.money_in?(kind)
      @amount.to_d.abs
    else
      @amount.to_d
    end
  end
end
