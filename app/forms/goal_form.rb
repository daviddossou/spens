# frozen_string_literal: true

class GoalForm < BaseForm
  ##
  # Attributes
  attr_accessor :space, :account

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
  def initialize(space, payload = {})
    @space = space
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
    AccountSuggestionsService.new(space).all_with_balances
  end

  def default_account_suggestions
    AccountSuggestionsService.new(space).defaults_with_balances
  end

  private

  def saving_goal_greater_than_balance
    return unless saving_goal.present? && current_balance.present?
    return if saving_goal > current_balance

    errors.add(:saving_goal, I18n.t("errors.messages.goal_must_be_greater"))
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
    transaction_form.submit

    raise StandardError, transaction_form.errors.full_messages.join(", ") unless transaction_form.errors.empty?
  end
end
