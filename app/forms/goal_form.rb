# frozen_string_literal: true

class GoalForm < BaseForm
  ##
  # Attributes
  attr_accessor :space, :account

  attribute :account_name, :string
  attribute :current_balance, :decimal
  attribute :savings_goal_amount, :decimal
  attribute :savings_goal_deadline, :date

  ##
  # Validations
  validates :account_name, presence: true
  validates :current_balance, numericality: true, allow_blank: true
  validates :savings_goal_amount, numericality: { greater_than: 0 }, allow_blank: true
  validate :goal_greater_than_balance
  validate :deadline_in_the_future

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
      savings_goal_amount: payload[:savings_goal_amount],
      savings_goal_deadline: payload[:savings_goal_deadline]
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
      # Creating through the goal flow marks the account as a savings goal, even
      # before a target amount is set.
      account.update!(savings_goal: true, savings_goal_amount: savings_goal_amount,
                      savings_goal_deadline: savings_goal_deadline)
      adjust_account_balance(account) if current_balance.present? && balance_changed?(account)
      # Balance moved through the ledger; reload so the plan spreads the real remainder.
      Budgets::SyncGoalPlanService.call(account.reload)
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

  def goal_greater_than_balance
    return unless savings_goal_amount.present? && current_balance.present?
    return if savings_goal_amount > current_balance

    errors.add(:savings_goal_amount, I18n.t("errors.messages.goal_must_be_greater"))
  end

  def deadline_in_the_future
    return if savings_goal_deadline.blank? || savings_goal_deadline > Date.current

    errors.add(:savings_goal_deadline, I18n.t("goals.errors.deadline_in_past"))
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
