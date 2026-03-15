# frozen_string_literal: true

class NormalizeAmountService
  def initialize(amount:, transaction_type:)
    @amount = amount
    @transaction_type = transaction_type
  end

  def call
    case @transaction_type.kind
    when "expense", "transfer_out", "debt_out"
      -@amount.to_d.abs
    when "income", "transfer_in", "debt_in"
      @amount.to_d.abs
    else
      @amount.to_d
    end
  end
end
