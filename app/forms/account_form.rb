# frozen_string_literal: true

class AccountForm < BaseForm
  ##
  # Attributes
  attr_accessor :space, :account, :user

  attribute :account_name, :string
  attribute :current_balance, :decimal
  attribute :set_aside, :boolean, default: false

  ##
  # Validations
  validates :account_name, presence: true, length: { maximum: 100 }
  validates :current_balance, numericality: true, allow_blank: true

  ##
  # Class Methods
  class << self
    def model_name
      ActiveModel::Name.new(self, nil, "Account")
    end
  end

  ##
  # Instance Methods
  def initialize(space, payload = {})
    @space = space
    @account = Account.find(payload[:id]) if payload[:id].present?

    super(
      account_name: payload[:account_name],
      current_balance: payload[:current_balance],
      set_aside: payload.key?(:set_aside) ? payload[:set_aside] : (@account&.set_aside || false)
    )
  end

  def persisted?
    @account.present?
  end

  def to_model
    self
  end

  def submit
    return false if invalid?

    ActiveRecord::Base.transaction do
      if persisted?
        update_account
      else
        create_account
      end
      account
    end
  rescue StandardError => e
    Rails.logger.error "AccountForm submit error: #{e.message}\n#{e.backtrace.join("\n")}"
    add_custom_error(:base, e.message)
    false
  end

  def account_suggestions
    AccountSuggestionsService.new(space).all_with_balances
  end

  def default_account_suggestions
    AccountSuggestionsService.new(space).defaults_with_balances
  end

  private

  def create_account
    @account = find_or_create_account
    @account.update!(user: user || @account.user, set_aside: set_aside)
    # The first balance set on a new account is its opening balance.
    record_balance_movement(account, "initial_balance") if current_balance.present? && balance_changed?(account)
  end

  def update_account
    account.update!(name: account_name.strip, set_aside: set_aside)
    # A later balance change is a reconciliation, not a real flow.
    record_balance_movement(account, "adjustment") if current_balance.present? && balance_changed?(account)
  end

  def find_or_create_account
    FindOrCreateAccountService.new(space, account_name).call
  end

  def balance_changed?(account)
    current_balance.to_f != account.balance
  end

  # A balance movement is a single neutral transaction (initial_balance on
  # creation, adjustment on edit). It carries the SIGNED delta so the ledger
  # moves the balance the right way; NormalizeAmountService preserves that sign
  # for neutral kinds. No matching leg (unlike a transfer), no cash flow.
  def record_balance_movement(account, kind)
    difference = current_balance.to_f - account.balance
    name = balance_movement_name(kind)
    type = FindOrCreateTransactionTypeService.new(space, name, kind).call

    CreateTransactionService.new(
      space: space,
      user: user,
      account: account,
      transaction_type: type,
      amount: difference,
      transaction_date: Date.current,
      description: name
    ).call
  end

  def balance_movement_name(kind)
    key = kind == "initial_balance" ? "initial_balance" : "balance_adjustment"
    I18n.t("transactions.#{key}.type_name")
  end
end
