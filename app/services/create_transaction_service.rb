# frozen_string_literal: true

class CreateTransactionService
  def initialize(user, account, transaction_type, amount, transaction_date, note, description)
    @user = user
    @account = account
    @transaction_type = transaction_type
    @amount = amount
    @transaction_date = transaction_date
    @note = note
    @description = description
  end

  def call
    transaction = @user.transactions.new(
      account: @account,
      transaction_type: @transaction_type,
      amount: -@amount.abs, # Negative for expense
      transaction_date: @transaction_date,
      note: @note,
      description: @description
    )

    if transaction.invalid?
      raise ActiveRecord::RecordInvalid, transaction
    end

    transaction.save!
    transaction
  end
end
