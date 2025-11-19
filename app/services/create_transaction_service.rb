# frozen_string_literal: true

class CreateTransactionService
  def initialize(user:, **attributes)
    @user = user
    @attributes = attributes
  end

  def call
    transaction = @user.transactions.new(
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
    case @attributes[:transaction_type].kind
    when "expense", "transfer_out", "debt_out"
      -@attributes[:amount].abs
    when "income", "transfer_in", "debt_in"
      @attributes[:amount].abs
    else
      @attributes[:amount]
    end
  end
end
