# frozen_string_literal: true

class CreateTransactionService
  def initialize(space:, **attributes)
    @space = space
    @attributes = attributes
  end

  def call
    transaction = @space.transactions.new(
      user: @attributes[:user],
      account: @attributes[:account],
      transaction_type: @attributes[:transaction_type],
      amount: normalized_amount,
      transaction_date: @attributes[:transaction_date],
      note: @attributes[:note],
      description: @attributes[:description],
      debt: @attributes[:debt],
      transfer_group_id: @attributes[:transfer_group_id],
      fee_parent_id: @attributes[:fee_parent_id]
    )

    if transaction.invalid?
      raise ActiveRecord::RecordInvalid, transaction
    end

    ActiveRecord::Base.transaction do
      transaction.save!
      TransactionLedger.apply(TransactionLedger.snapshot(transaction))
    end

    transaction
  end

  private

  def normalized_amount
    NormalizeAmountService.new(amount: @attributes[:amount], transaction_type: @attributes[:transaction_type]).call
  end
end
