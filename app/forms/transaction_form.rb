# frozen_string_literal: true

class TransactionForm < BaseForm
  ##
  # Attributes
  attr_accessor :user, :transaction

  attribute :kind, :string, default: 'expense'
  attribute :account_name, :string
  attribute :amount, :decimal
  attribute :transaction_date, :date, default: -> { Date.current }
  attribute :transaction_type_name, :string
  attribute :note, :string

  ##
  # Validations
  validates :kind, presence: true, inclusion: { in: %w[expense] }
  validates :account_name, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_date, presence: true
  validates :transaction_type_name, presence: true

  ##
  # Class Methods
  class << self
    def model_name
      ActiveModel::Name.new(self, nil, "Transaction")
    end
  end

  ##
  # Instance Methods
  def initialize(user, payload = {})
    @user = user
    super(
      kind: payload[:kind] || 'expense',
      account_name: payload[:account_name],
      amount: payload[:amount],
      transaction_date: payload[:transaction_date] || Date.current,
      transaction_type_name: payload[:transaction_type_name],
      note: payload[:note]
    )
  end

  def persisted?
    false
  end

  def to_model
    self
  end

  def submit
    return false if invalid?

    ActiveRecord::Base.transaction do
      account = find_or_create_account
      transaction_type = find_or_create_transaction_type
      create_transaction(account, transaction_type)
    end

    true
  rescue StandardError => e
    Rails.logger.error "TransactionForm submit error: #{e.message}\n#{e.backtrace.join("\n")}"
    add_custom_error(:base, e.message)
    false
  end

  def transaction_type_suggestions
    TransactionTypeSuggestionsService.new(user, kind).all
  end

  def default_transaction_type_suggestions
    TransactionTypeSuggestionsService.new(user, kind).defaults
  end

  def account_suggestions
    AccountSuggestionsService.new(user).all
  end

  def default_account_suggestions
    AccountSuggestionsService.new(user).defaults
  end

  private

  def find_or_create_account
    FindOrCreateAccountService.new(user, account_name).call
  end

  def find_or_create_transaction_type
    FindOrCreateTransactionTypeService.new(user, transaction_type_name, kind).call
  end

  def create_transaction(account, transaction_type)
    transaction = CreateTransactionService.new(
      user,
      account,
      transaction_type,
      amount,
      transaction_date,
      note,
      transaction_type_name
    ).call

    if transaction.invalid?
      promote_errors(transaction.errors.messages)
    end

    transaction
  end
end
