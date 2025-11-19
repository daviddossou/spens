# frozen_string_literal: true

class Onboarding::TransactionForm < BaseForm
  ##
  # Constants
  DEFAULT_TRANSACTION_TYPE_NAME = "Transfer In"
  DEFAULT_TRANSACTION_TYPE_KIND = TransactionType::KIND_TRANSFER_IN

  ##
  # Attributes
  attribute :account_name, :string
  attribute :amount, :decimal
  attribute :transaction_date, :date, default: -> { Date.current }
  attribute :transaction_type_name, :string, default: DEFAULT_TRANSACTION_TYPE_NAME
  attribute :transaction_type_kind, :string, default: DEFAULT_TRANSACTION_TYPE_KIND

  attr_accessor :user

  ##
  # Validations
  validates :account_name, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_date, presence: true
  validates :transaction_type_name, presence: true
  validates :transaction_type_kind, inclusion: { in: TransactionType.kinds.keys }

  ##
  # Class Methods
  class << self
    def model_name
      ActiveModel::Name.new(self, nil, "onboarding_transaction_form")
    end
  end

  ##
  # Instance Methods
  def initialize(user:, **attributes)
    @user = user
    super(**attributes)
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
      transaction = create_transaction(account, transaction_type)

      transaction
    end
  rescue StandardError => e
    Rails.logger.error "Onboarding::TransactionForm submit error: #{e.message}\n#{e.backtrace.join("\n")}"
    add_custom_error(:base, e.message)
    false
  end

  def should_skip?
    account_name.blank? || amount.to_f <= 0
  end

  private

  def find_or_create_account
    FindOrCreateAccountService.new(user, account_name).call
  end

  def find_or_create_transaction_type
    FindOrCreateTransactionTypeService.new(user, transaction_type_name, transaction_type_kind).call
  end

  def create_transaction(account, transaction_type)
    description = I18n.t("onboarding.account_setups.initial_balance_description", account_name: account.name)

    transaction = CreateTransactionService.new(
      user: user,
      account: account,
      transaction_type: transaction_type,
      amount: amount,
      transaction_date: transaction_date,
      description: description
    ).call

    if transaction.invalid?
      promote_errors(transaction.errors.messages)
    end

    transaction
  end
end
