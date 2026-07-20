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
  attribute :fee_amount, :decimal
  attribute :transaction_date, :date, default: -> { Date.current }
  attribute :transaction_type_name, :string
  attribute :note, :string
  attribute :description, :string
  attribute :contact_name, :string
  attribute :direction, :string
  # Set when the quick-entry fallback rendered this form, so the created transaction can be
  # linked back to its QuickEntryAttempt and feed the learning loop.
  attribute :quick_entry_attempt_id, :string

  ##
  # Validations
  validates :kind, presence: true, inclusion: { in: %w[expense income transfer transfer_in transfer_out debt_in debt_out] }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :fee_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :transaction_date, presence: true

  # Conditional validations based on kind
  validates :transaction_type_name, presence: true, unless: -> { transfer? || debt_transaction? }
  validates :from_account_name, presence: true, if: :double_transfer?
  validates :to_account_name, presence: true, if: :double_transfer?
  validate :different_accounts_for_transfer, if: :double_transfer?

  # Debt entry from the main form: a person and a direction are required when no
  # existing debt was pre-selected (i.e. not launched from a debt's detail page).
  validates :contact_name, presence: true, if: -> { debt_transaction? && @debt_id.blank? }
  validates :direction, presence: true, if: -> { debt_transaction? && @debt_id.blank? }
  validates :direction, inclusion: { in: %w[lent borrowed] }, allow_blank: true, if: :debt_transaction?

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
      txn_kind = @transaction.transaction_type.kind
      # A transfer is presented as the single top-level "transfer" kind, not its
      # per-leg transfer_in/transfer_out, so the kind selector and the pair-edit
      # path resolve correctly.
      payload[:kind] ||= TransactionKind.transfer?(txn_kind) ? "transfer" : txn_kind
      payload[:amount] ||= @transaction.amount.abs
      payload[:description] ||= @transaction.description
      payload[:transaction_date] ||= @transaction.transaction_date
      payload[:transaction_type_name] ||= @transaction.transaction_type.name
      payload[:note] ||= @transaction.note
      payload[:account_name] ||= @transaction.account&.name
      payload[:contact_name] ||= @transaction.debt&.name
      payload[:direction] ||= @transaction.debt&.direction

      fee_carrier = TransactionKind.transfer?(txn_kind) ? @transaction.transfer_legs[:out] : @transaction
      payload[:fee_amount] ||= fee_carrier&.fee&.amount&.abs

      if TransactionKind.transfer?(txn_kind)
        legs = @transaction.transfer_legs
        payload[:from_account_name] ||= legs[:out]&.account&.name
        payload[:to_account_name] ||= legs[:in]&.account&.name
      end
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
      fee_amount: payload[:fee_amount],
      transaction_date: payload[:transaction_date] || Date.current,
      transaction_type_name: payload[:transaction_type_name],
      note: payload[:note],
      description: payload[:description],
      contact_name: payload[:contact_name],
      direction: payload[:direction],
      quick_entry_attempt_id: payload[:quick_entry_attempt_id]
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
      self.transaction = (editing? ? EditTransaction : BuildTransaction).new(self).call
    end

    true
  rescue StandardError => e
    Rails.logger.error "TransactionForm submit error: #{e.message}\n#{e.backtrace.join("\n")}"
    add_custom_error(:base, e.message)
    false
  end

  ##
  # View data (autocomplete options / suggestions)
  def transaction_type_options
    TransactionTypeSuggestionsService.new(space, kind).options
  end

  def default_transaction_type_options
    TransactionTypeSuggestionsService.new(space, kind).default_options
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
    if TransactionKind.debt?(target_kind)
      params[:debt_id] = debt_id if debt_id.present?
      params[:direction] = direction if direction.present?
      params[:contact_name] = contact_name if contact_name.present?
    end
    params
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

  ##
  # Predicates / resolution
  def debt_transaction?
    debt_id.present? || TransactionKind.debt?(kind)
  end

  def transfer?
    TransactionKind.transfer?(kind)
  end

  # A fee only applies when money leaves the user's account — never on income or
  # debt_in, where the sender pays the fee, not the user.
  def fee_applicable?
    TransactionKind.fee_applicable?(kind)
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

  private

  def double_transfer?
    kind == "transfer"
  end

  def different_accounts_for_transfer
    return unless from_account_name.present? && to_account_name.present? &&
                  from_account_name.strip.downcase == to_account_name.strip.downcase

    errors.add(:to_account_name, I18n.t("errors.messages.different_account"))
  end
end
