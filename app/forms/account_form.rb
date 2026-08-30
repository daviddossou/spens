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
    adjust_account_balance(account) if current_balance.present? && balance_changed?(account)
  end

  def update_account
    account.update!(name: account_name.strip, set_aside: set_aside)
    adjust_account_balance(account) if current_balance.present? && balance_changed?(account)
  end

  def find_or_create_account
    FindOrCreateAccountService.new(space, account_name).call
  end

  def balance_changed?(account)
    current_balance.to_f != account.balance
  end

  # A balance adjustment is a single income (top-up) or expense (drawdown)
  # transaction — not a transfer, which would require a matching second leg.
  def adjust_account_balance(account)
    difference = current_balance.to_f - account.balance
    kind = difference.positive? ? "income" : "expense"

    create_adjustment_transaction(account, difference.abs, kind)
  end

  def create_adjustment_transaction(account, amount, kind)
    params = {
      account_id: account.id,
      account_name: account.name,
      amount: amount,
      transaction_date: Date.current,
      transaction_type_name: I18n.t("transactions.balance_adjustment.type_name"),
      kind: kind
    }

    transaction_form = TransactionForm.new(space, params)
    transaction_form.user = user
    transaction_form.submit

    raise StandardError, transaction_form.errors.full_messages.join(", ") unless transaction_form.errors.empty?
  end
end
