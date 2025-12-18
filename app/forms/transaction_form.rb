# frozen_string_literal: true

class TransactionForm < BaseForm
  ##
  # Attributes
  attr_accessor :user, :transaction, :debt
  attr_reader :account_id, :debt_id

  attribute :kind, :string, default: "expense"
  attribute :account_name, :string
  attribute :from_account_name, :string
  attribute :to_account_name, :string
  attribute :amount, :decimal
  attribute :transaction_date, :date, default: -> { Date.current }
  attribute :transaction_type_name, :string
  attribute :note, :string

  ##
  # Validations
  validates :kind, presence: true, inclusion: { in: %w[expense income transfer transfer_in transfer_out debt_in debt_out] }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_date, presence: true

  # Conditional validations based on kind
  validates :account_name, presence: true, unless: -> { transfer? || debt_transaction? }
  validates :transaction_type_name, presence: true, unless: -> { transfer? || debt_transaction? }
  validates :from_account_name, presence: true, if: :double_transfer?
  validates :to_account_name, presence: true, if: :double_transfer?
  validate :different_accounts_for_transfer, if: :double_transfer?

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
    @debt_id = payload[:debt_id]

    if @debt_id.present?
      @debt = user.debts.find_by(id: @debt_id)
    end

    if @account_id.present?
      account = user.accounts.find_by(id: @account_id)
      if account
        payload[:account_name] ||= account.name
        payload[:to_account_name] ||= account.name if payload[:kind] == "transfer"
      end
    end

    super(
      kind: payload[:kind] || "expense",
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
      elsif debt_transaction?
        create_debt_transaction
      else
        create_regular_transaction
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
    params[:debt_id] = debt_id if debt_id.present?
    params
  end

  def debt_transaction?
    debt_id.present? || %w[debt_in debt_out].include?(kind)
  end

  private

  def transfer?
    [ "transfer", "transfer_in", "transfer_out" ].include?(kind)
  end

  def double_transfer?
    kind == "transfer"
  end

  def different_accounts_for_transfer
    return unless from_account_name.present? && to_account_name.present? &&
                  from_account_name.strip.downcase == to_account_name.strip.downcase

    errors.add(:to_account_name, I18n.t("errors.messages.different_account"))
  end

  def create_regular_transaction
    create_and_validate_transaction(
      account: find_or_create_account,
      transaction_type: find_or_create_transaction_type,
      amount: amount,
      description: transaction_type_name
    )
  end

  def create_transfer_transactions
    create_transfer_in_transaction
    create_transfer_out_transaction
  end

  def create_transfer_in_transaction
    return unless kind == "transfer" || kind == "transfer_in"

    description = transaction_type_name.presence || I18n.t("transactions.transfer.description_in", from_account_name: from_account.name, to_account_name: to_account.name)

    create_and_validate_transaction(
      account: to_account,
      transaction_type: transfer_type_in,
      amount: amount,
      description: description
    )
  end

  def create_transfer_out_transaction
    return unless kind == "transfer" || kind == "transfer_out"

    description = transaction_type_name.presence || I18n.t("transactions.transfer.description_out", from_account_name: from_account.name, to_account_name: to_account.name)

    create_and_validate_transaction(
      account: from_account,
      transaction_type: transfer_type_out,
      amount: amount,
      description: description
    )
  end

  def create_debt_transaction
    description = I18n.t("debts.transaction_description.#{kind}.#{debt.direction}", contact_name: debt.name)
    type_name = I18n.t("debts.transaction_type.#{kind}.#{debt.direction}")

    create_and_validate_transaction(
      account: find_or_create_account,
      transaction_type: find_or_create_transaction_type(type_name, kind),
      amount: amount,
      description: description,
      debt: debt
    )
  end

  def create_and_validate_transaction(account:, transaction_type:, amount:, description:, debt: nil)
    transaction = CreateTransactionService.new(
      user: user,
      account: account,
      transaction_type: transaction_type,
      amount: amount.abs,
      transaction_date: transaction_date,
      note: note,
      description: description,
      debt: debt
    ).call

    if transaction.invalid?
      promote_errors(transaction.errors.messages)
      raise ActiveRecord::RecordInvalid, transaction
    end

    transaction
  end

  def find_or_create_account
    return nil if debt_transaction? && account_name.blank?

    FindOrCreateAccountService.new(user, account_name).call
  end

  def find_or_create_transaction_type(type_name = transaction_type_name, kind_name = kind)
    FindOrCreateTransactionTypeService.new(user, type_name, kind_name).call
  end

  def from_account
    @from_account ||= FindOrCreateAccountService.new(user, (from_account_name || account_name)).call
  end

  def to_account
    @to_account ||= FindOrCreateAccountService.new(user, (to_account_name || account_name)).call
  end

  def transfer_type_out
    type_name = I18n.t("transactions.transfer.type_name.#{TransactionType::KIND_TRANSFER_OUT}")
    @transfer_type_out ||= find_or_create_transaction_type(type_name, TransactionType::KIND_TRANSFER_OUT)
  end

  def transfer_type_in
    type_name = I18n.t("transactions.transfer.type_name.#{TransactionType::KIND_TRANSFER_IN}")
    @transfer_type_in ||= find_or_create_transaction_type(type_name, TransactionType::KIND_TRANSFER_IN)
  end
end
