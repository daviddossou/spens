# frozen_string_literal: true

class TransactionForm < BaseForm
  ##
  # Attributes
  attr_accessor :space, :transaction, :user
  attr_writer :debt
  attr_reader :account_id, :debt_id

  attribute :kind, :string, default: "expense"
  attribute :account_name, :string
  attribute :from_account_name, :string
  attribute :to_account_name, :string
  attribute :amount, :decimal
  attribute :transaction_date, :date, default: -> { Date.current }
  attribute :transaction_type_name, :string
  attribute :note, :string
  attribute :description, :string
  attribute :contact_name, :string
  attribute :direction, :string

  ##
  # Validations
  validates :kind, presence: true, inclusion: { in: %w[expense income transfer transfer_in transfer_out debt_in debt_out] }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_date, presence: true

  # Conditional validations based on kind
  validates :transaction_type_name, presence: true, unless: -> { transfer? || debt_transaction? }
  validate :at_least_one_transfer_account, if: :double_transfer?
  validate :different_accounts_for_transfer, if: :double_transfer?

  # Debt entry from the main form: a person and a direction are required when no
  # existing debt was pre-selected (i.e. not launched from a debt's detail page).
  validates :contact_name, presence: true, if: -> { debt_transaction? && @debt_id.blank? }
  validates :direction, presence: true, inclusion: { in: %w[lent borrowed] }, if: -> { debt_transaction? && @debt_id.blank? }

  ##
  # Class Methods
  class << self
    def model_name
      ActiveModel::Name.new(self, nil, "Transaction")
    end
  end

  ##
  # Instance Methods
  def initialize(space, payload = {})
    @space = space
    @transaction = payload.delete(:transaction)
    @account_id = payload[:account_id]
    @debt_id = payload[:debt_id]

    if @debt_id.present?
      @debt = space.debts.find_by(id: @debt_id)
      if @debt
        payload[:direction] ||= @debt.direction
        payload[:contact_name] ||= @debt.name
      end
    end

    if editing?
      payload[:kind] ||= @transaction.transaction_type.kind
      payload[:amount] ||= @transaction.amount.abs
      payload[:description] ||= @transaction.description
      payload[:transaction_date] ||= @transaction.transaction_date
      payload[:transaction_type_name] ||= @transaction.transaction_type.name
      payload[:note] ||= @transaction.note
      payload[:account_name] ||= @transaction.account&.name
      payload[:contact_name] ||= @transaction.debt&.name
      payload[:direction] ||= @transaction.debt&.direction
    end

    if @account_id.present? && !editing?
      account = space.accounts.find_by(id: @account_id)
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
      note: payload[:note],
      description: payload[:description],
      contact_name: payload[:contact_name],
      direction: payload[:direction]
    )
  end

  def editing?
    @transaction&.persisted? || false
  end

  def persisted?
    editing?
  end

  def to_key
    editing? ? [ @transaction.id ] : nil
  end

  def to_model
    self
  end

  def submit
    return false if invalid?

    ActiveRecord::Base.transaction do
      if editing?
        update_existing_transaction
      elsif transfer?
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
    TransactionTypeSuggestionsService.new(space, kind).all
  end

  def default_transaction_type_suggestions
    TransactionTypeSuggestionsService.new(space, kind).defaults
  end

  def account_suggestions
    AccountSuggestionsService.new(space).all_with_balances
  end

  def default_account_suggestions
    AccountSuggestionsService.new(space).defaults_with_balances
  end

  def kind_params(target_kind)
    params = { kind: target_kind }
    params[:account_id] = account_id if account_id.present?
    # Only carry the debt context onto debt-kind targets, so switching to
    # expense/income/transfer cleanly drops it.
    if %w[debt_in debt_out].include?(target_kind)
      params[:debt_id] = debt_id if debt_id.present?
      params[:direction] = direction if direction.present?
      params[:contact_name] = contact_name if contact_name.present?
    end
    params
  end

  def debt_transaction?
    debt_id.present? || %w[debt_in debt_out].include?(kind)
  end

  # Resolves the debt for this transaction. When launched from a debt's detail
  # page, @debt is set from @debt_id. From the main form, the debt is found (or
  # created) from the typed person name + chosen direction.
  def debt
    @debt ||= if @debt_id.present?
                space.debts.find_by(id: @debt_id)
              elsif contact_name.present? && direction.present?
                FindOrCreateDebtService.new(space, contact_name, direction, user).call
              end
  end

  # Person options for the "Who?" autocomplete: distinct ongoing-debt names.
  def debt_person_suggestions
    space.debts.ongoing.order(updated_at: :desc).pluck(:name).uniq
  end

  # Map of lowercased person name => [directions], so the client can infer a
  # direction for an existing person (and disambiguate a name used both ways).
  def debts_by_name
    space.debts.ongoing.each_with_object({}) do |debt, acc|
      key = debt.name.to_s.strip.downcase
      (acc[key] ||= []) << debt.direction
      acc[key].uniq!
    end
  end

  def transfer?
    [ "transfer", "transfer_in", "transfer_out" ].include?(kind)
  end

  private

  def double_transfer?
    kind == "transfer"
  end

  def different_accounts_for_transfer
    return unless from_account_name.present? && to_account_name.present? &&
                  from_account_name.strip.downcase == to_account_name.strip.downcase

    errors.add(:to_account_name, I18n.t("errors.messages.different_account"))
  end

  def at_least_one_transfer_account
    return if from_account_name.present? || to_account_name.present?

    errors.add(:from_account_name, :blank)
  end

  def create_regular_transaction
    self.transaction = create_and_validate_transaction(
      account: find_or_create_account,
      transaction_type: find_or_create_transaction_type,
      amount: amount,
      description: description.presence || transaction_type_name
    )
  end

  def create_transfer_transactions
    create_transfer_in_transaction
    create_transfer_out_transaction
  end

  def create_transfer_in_transaction
    return unless kind == "transfer" || kind == "transfer_in"

    auto_description = transaction_type_name.presence || I18n.t("transactions.transfer.description_in", from_account_name: from_account.name, to_account_name: to_account.name)

    self.transaction = create_and_validate_transaction(
      account: to_account,
      transaction_type: transfer_type_in,
      amount: amount,
      description: description.presence || auto_description
    )
  end

  def create_transfer_out_transaction
    return unless kind == "transfer" || kind == "transfer_out"

    auto_description = transaction_type_name.presence || I18n.t("transactions.transfer.description_out", from_account_name: from_account.name, to_account_name: to_account.name)

    self.transaction = create_and_validate_transaction(
      account: from_account,
      transaction_type: transfer_type_out,
      amount: amount,
      description: description.presence || auto_description
    )
  end

  def create_debt_transaction
    auto_description = I18n.t("debts.transaction_description.#{kind}.#{debt.direction}", contact_name: debt.name)
    type_name = I18n.t("debts.transaction_type.#{kind}.#{debt.direction}")

    self.transaction = create_and_validate_transaction(
      account: find_or_create_account,
      transaction_type: find_or_create_transaction_type(type_name, kind),
      amount: amount,
      description: description.presence || auto_description,
      debt: debt
    )
  end

  def create_and_validate_transaction(account:, transaction_type:, amount:, description:, debt: nil)
    transaction = CreateTransactionService.new(
      space: space,
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
    return nil if account_name.blank?

    FindOrCreateAccountService.new(space, account_name).call
  end

  def find_or_create_transaction_type(type_name = transaction_type_name, kind_name = kind)
    FindOrCreateTransactionTypeService.new(space, type_name, kind_name).call
  end

  def from_account
    @from_account ||= FindOrCreateAccountService.new(space, (from_account_name || account_name)).call
  end

  def to_account
    @to_account ||= FindOrCreateAccountService.new(space, (to_account_name || account_name)).call
  end

  def transfer_type_out
    type_name = I18n.t("transactions.transfer.type_name.#{TransactionType::KIND_TRANSFER_OUT}")
    @transfer_type_out ||= find_or_create_transaction_type(type_name, TransactionType::KIND_TRANSFER_OUT)
  end

  def transfer_type_in
    type_name = I18n.t("transactions.transfer.type_name.#{TransactionType::KIND_TRANSFER_IN}")
    @transfer_type_in ||= find_or_create_transaction_type(type_name, TransactionType::KIND_TRANSFER_IN)
  end

  def update_existing_transaction
    # For debt transactions, only re-derive the type when the kind actually
    # changes (debt_in <-> debt_out) so it relabels correctly
    # (e.g. "Repayment Received" -> "Money Lent"). When unchanged, keep the
    # existing name verbatim to avoid case drift against the stored type.
    debt = @transaction.debt
    type_name =
      if debt_transaction? && debt && kind != @transaction.transaction_type.kind
        I18n.t("debts.transaction_type.#{kind}.#{debt.direction}")
      else
        transaction_type_name
      end

    self.transaction = UpdateTransactionService.new(
      transaction: @transaction,
      attributes: {
        kind: kind,
        description: description,
        transaction_date: transaction_date,
        transaction_type_name: type_name,
        account_name: account_name,
        amount: amount,
        note: note
      }
    ).call
  end
end
