# frozen_string_literal: true

class GoalForm < BaseForm
  ##
  # Attributes
  attr_accessor :user

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
      account = find_or_create_account
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

    errors.add(:saving_goal, I18n.t('errors.messages.goal_must_be_greater'))
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

    create_adjustment_transaction(account, difference.abs, adjustment_type)
  end

  def create_adjustment_transaction(account, amount, type)
    transaction_type = find_or_create_transaction_type(*adjustment_params(type))

    CreateTransactionService.new(
      user,
      account,
      transaction_type,
      amount,
      Date.current,
      nil,
      transaction_type.name,
    ).call
  end

  def adjustment_params(type)
    case type
    when :transfer_in
      [I18n.t('transactions.transfer.type_name.transfer_in'), TransactionType::KIND_TRANSFER_IN]
    when :transfer_out
      [I18n.t('transactions.transfer.type_name.transfer_out'), TransactionType::KIND_TRANSFER_OUT]
    end
  end

  def find_or_create_transaction_type(name, kind)
    FindOrCreateTransactionTypeService.new(user, name, kind).call
  end
end
