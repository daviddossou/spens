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
      amount: normalized_amount,
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

  private

  def normalized_amount
    case @transaction_type.kind
    when "expense", "loan", "transfer_out", "debt"
      -@amount.abs
    when "income", "transfer_in"
      @amount.abs
    else
      @amount
    end
  end
end
