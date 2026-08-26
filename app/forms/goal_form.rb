# frozen_string_literal: true

class GoalForm < BaseForm
  ##
  # Attributes
  attr_accessor :space, :account, :goal

  attribute :goal_name, :string
  attribute :account_name, :string
  attribute :current_balance, :decimal
  attribute :target_amount, :decimal
  attribute :deadline, :date

  ##
  # Validations
  validates :goal_name, presence: true, length: { maximum: 100 }
  validates :account_name, presence: true
  validates :current_balance, numericality: true, allow_blank: true
  validates :target_amount, numericality: { greater_than: 0 }, allow_blank: true
  validate :target_greater_than_balance
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
    @goal = Goal.find(payload[:id]) if payload[:id].present?
    super(
      goal_name: payload[:goal_name],
      account_name: payload[:account_name],
      current_balance: payload[:current_balance],
      target_amount: payload[:target_amount],
      deadline: payload[:deadline]
    )
  end

  def persisted?
    @goal.present?
  end

  def to_key
    persisted? ? [ @goal.id ] : nil
  end

  def to_model
    self
  end

  def submit
    return false if invalid?

    ActiveRecord::Base.transaction do
      @account = find_or_create_account
      adjust_account_balance(account) if current_balance.present? && balance_changed?(account)
      @goal = upsert_goal(account.reload)
      # Balance settled through the ledger; the plan spreads the real remainder.
      Budgets::SyncGoalPlanService.call(goal)
      goal
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

  def upsert_goal(account)
    goal = @goal || space.goals.find_or_initialize_by(account: account)
    goal.assign_attributes(name: goal_name, target_amount: target_amount, deadline: deadline)
    goal.save!
    goal
  end

  def target_greater_than_balance
    return unless target_amount.present? && current_balance.present?
    return if target_amount > current_balance

    errors.add(:target_amount, I18n.t("errors.messages.goal_must_be_greater"))
  end

  def deadline_in_the_future
    return if deadline.blank? || deadline > Date.current

    errors.add(:deadline, I18n.t("goals.errors.deadline_in_past"))
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
