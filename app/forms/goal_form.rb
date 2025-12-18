# frozen_string_literal: true

class GoalForm < BaseForm
  ##
  # Attributes
  attr_accessor :user, :account

  attribute :account_name, :string
  attribute :current_balance, :decimal
  attribute :saving_goal, :decimal

  ##
  # Validations
  validates :account_name, presence: true
  validates :current_balance, presence: true, numericality: true
  validates :saving_goal, presence: true, numericality: { greater_than: 0 }
  validate :saving_goal_greater_than_balance

  ##
  # Class Methods
  class << self
    def model_name
      ActiveModel::Name.new(self, nil, "Goal")
    end
  end

  ##
  # Instance Methods
  def initialize(user, payload = {})
    @user = user
    super(
      account_name: payload[:account_name],
      current_balance: payload[:current_balance],
      saving_goal: payload[:saving_goal]
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
      @account = find_or_create_account
      account.update!(saving_goal: saving_goal)
      adjust_account_balance(account) if balance_changed?(account)
      account
    end
  rescue StandardError => e
    Rails.logger.error "GoalForm submit error: #{e.message}\n#{e.backtrace.join("\n")}"
    add_custom_error(:base, e.message)
    false
  end

  def account_suggestions
    AccountSuggestionsService.new(user).all_with_balances
  end

  def default_account_suggestions
    AccountSuggestionsService.new(user).defaults_with_balances
  end

  private

  def saving_goal_greater_than_balance
    return unless saving_goal.present? && current_balance.present?
    return if saving_goal > current_balance

    errors.add(:saving_goal, I18n.t("errors.messages.goal_must_be_greater"))
  end

  def find_or_create_account
    FindOrCreateAccountService.new(user, account_name).call
  end

  def balance_changed?(account)
    current_balance.to_f != account.balance
  end

  def adjust_account_balance(account)
    difference = current_balance.to_f - account.balance
    adjustment_type = difference.positive? ? :transfer_in : :transfer_out

    send("create_#{adjustment_type}_transaction", account, difference.abs)
  end

  def create_transfer_in_transaction(account, amount)
    create_adjustment_transaction(account, amount, :transfer_in, TransactionType::KIND_TRANSFER_IN)
  end

  def create_transfer_out_transaction(account, amount)
    create_adjustment_transaction(account, amount, :transfer_out, TransactionType::KIND_TRANSFER_OUT)
  end

  def create_adjustment_transaction(account, amount, type, kind)
    type_name = I18n.t("transactions.transfer.type_name.#{kind}")
    
    # For transfer_in, the money comes from an external source to this account
    # For transfer_out, the money goes from this account to an external destination
    adjustment_account_name = "Balance Adjustment"
    
    params = {
      account_id: account.id,
      amount: amount,
      transaction_date: Date.current,
      transaction_type_name: type_name,
      kind: kind
    }
    
    # Add the appropriate account names for the transfer direction
    if kind == TransactionType::KIND_TRANSFER_IN
      params[:to_account_name] = account.name
      params[:from_account_name] = adjustment_account_name
    else
      params[:from_account_name] = account.name
      params[:to_account_name] = adjustment_account_name
    end

    transaction_form = TransactionForm.new(user, params)
    transaction_form.submit

    raise StandardError, transaction_form.errors.full_messages.join(", ") unless transaction_form.errors.empty?
  end
end
