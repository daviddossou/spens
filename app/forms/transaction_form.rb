# frozen_string_literal: true

class TransactionForm < BaseForm
  ##
  # Attributes
  attr_accessor :user, :transaction
  attr_reader :account_id

  attribute :kind, :string, default: 'expense'
  attribute :account_name, :string
  attribute :from_account_name, :string
  attribute :to_account_name, :string
  attribute :amount, :decimal
  attribute :transaction_date, :date, default: -> { Date.current }
  attribute :transaction_type_name, :string
  attribute :note, :string

  ##
  # Validations
  validates :kind, presence: true, inclusion: { in: %w[expense income transfer loan debt] }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_date, presence: true

  # Conditional validations based on kind
  validates :account_name, presence: true, unless: :transfer?
  validates :transaction_type_name, presence: true, unless: :transfer?
  validates :from_account_name, presence: true, if: :transfer?
  validates :to_account_name, presence: true, if: :transfer?
  validate :different_accounts_for_transfer, if: :transfer?

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
    @account_id = payload[:account_id]

    if @account_id.present?
      account = user.accounts.find_by(id: @account_id)
      if account
        payload[:account_name] ||= account.name
        payload[:to_account_name] ||= account.name if payload[:kind] == 'transfer'
      end
    end

    super(
      kind: payload[:kind] || 'expense',
      account_name: payload[:account_name],
      from_account_name: payload[:from_account_name],
      to_account_name: payload[:to_account_name],
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
      if transfer?
        create_transfer_transactions
      else
        account = find_or_create_account
        transaction_type = find_or_create_transaction_type
        create_and_validate_transaction(
          account: account,
          transaction_type: transaction_type,
          amount: amount,
          description: transaction_type_name
        )
      end
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

  def kind_params(target_kind)
    params = { kind: target_kind }
    params[:account_id] = account_id if account_id.present?
    params
  end

  private

  def transfer?
    kind == 'transfer'
  end

  def different_accounts_for_transfer
    return unless from_account_name.present? && to_account_name.present? &&
                  from_account_name.strip.downcase == to_account_name.strip.downcase

    errors.add(:to_account_name, I18n.t('errors.messages.different_account'))
  end

  def find_or_create_account
    FindOrCreateAccountService.new(user, account_name).call
  end

  def find_or_create_transaction_type
    FindOrCreateTransactionTypeService.new(user, transaction_type_name, kind).call
  end

  def create_and_validate_transaction(account:, transaction_type:, amount:, description:)
    transaction = CreateTransactionService.new(
      user,
      account,
      transaction_type,
      amount,
      transaction_date,
      note,
      description
    ).call

    if transaction.invalid?
      promote_errors(transaction.errors.messages)
      raise ActiveRecord::RecordInvalid, transaction
    end

    transaction
  end

  def create_transfer_transactions
    transfer_out = create_and_validate_transaction(
      account: from_account,
      transaction_type: transfer_type_out,
      amount: amount,
      description: I18n.t('transactions.transfer.description_out', from_account_name: from_account.name, to_account_name: to_account.name)
    )

    transfer_in = create_and_validate_transaction(
      account: to_account,
      transaction_type: transfer_type_in,
      amount: amount,
      description: I18n.t('transactions.transfer.description_in', from_account_name: from_account.name, to_account_name: to_account.name)
    )

    [transfer_out, transfer_in]
  end

  def find_or_create_transfer_type(kind)
    type_name = I18n.t("transactions.transfer.type_name.#{kind}")
    FindOrCreateTransactionTypeService.new(user, type_name, kind).call
  end

  def from_account
    @from_account ||= FindOrCreateAccountService.new(user, from_account_name).call
  end

  def to_account
    @to_account ||= FindOrCreateAccountService.new(user, to_account_name).call
  end

  def transfer_type_out
    @transfer_type_out ||= find_or_create_transfer_type(TransactionType::KIND_TRANSFER_OUT)
  end

  def transfer_type_in
    @transfer_type_in ||= find_or_create_transfer_type(TransactionType::KIND_TRANSFER_IN)
  end
end
