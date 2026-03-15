# frozen_string_literal: true

class CreateTransactionService
  def initialize(space:, **attributes)
    @space = space
    @attributes = attributes
  end

  def call
    transaction = @space.transactions.new(
      account: @attributes[:account],
      transaction_type: @attributes[:transaction_type],
      amount: normalized_amount,
      transaction_date: @attributes[:transaction_date],
      note: @attributes[:note],
      description: @attributes[:description],
      debt: @attributes[:debt]
    )

    if transaction.invalid?
      raise ActiveRecord::RecordInvalid, transaction
    end

    transaction.save!
    transaction
  end

  private

  def normalized_amount
    NormalizeAmountService.new(amount: @attributes[:amount], transaction_type: @attributes[:transaction_type]).call
  end
end
