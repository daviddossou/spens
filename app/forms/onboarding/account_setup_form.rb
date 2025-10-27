# frozen_string_literal: true

class Onboarding::AccountSetupForm < BaseForm
  ##
  # Constants
  CURRENT_STEP = 'onboarding_account_setup'
  NEXT_STEP = 'onboarding_completed'
  TRANSACTION_TYPE_NAME = 'Transfer In'
  TRANSACTION_TYPE_KIND = 'transfer_in'

  ##
  # Attributes
  attr_accessor :user
  attr_reader :transactions

  ##
  # Validations
  validate :at_least_one_valid_transaction

  ##
  # Class Methods
  class << self
    def model_name
      ActiveModel::Name.new(self, nil, "onboarding_account_setup_form")
    end
  end

  ##
  # Instance Methods
  def initialize(user, payload = {})
    @user = user

    if payload[:transactions_attributes].present?
      self.transactions_attributes = payload[:transactions_attributes]
    else
      @transactions = default_transactions
    end

    user.onboarding_current_step ||= CURRENT_STEP
  end

  def transactions_attributes=(attributes)
    @transactions = attributes.values.map do |attrs|
      build_transaction_from_nested_attributes(attrs)
    end
  end

  def submit
    return false if invalid?

    ActiveRecord::Base.transaction do
      transactions.each do |transaction|
        next if should_skip_transaction?(transaction)

        persist_transaction(transaction)
      end

      user.onboarding_current_step = NEXT_STEP
      user.save!
    end
  rescue StandardError => e
    Rails.logger.error "AccountSetupForm submit error: #{e.message}\n#{e.backtrace.join("\n")}"
    add_custom_error(:base, e.message)

    false
  end

  private

  def default_transactions
    [
      user.transactions.new(
        amount: nil,
        transaction_date: Date.current
      ).tap do |transaction|
        transaction.account = Account.new(name: '')
        transaction.transaction_type = TransactionType.new(name: TRANSACTION_TYPE_NAME)
      end
    ]
  end

  def build_transaction_from_nested_attributes(attrs)
    user.transactions.new(
      amount: attrs[:amount],
      transaction_date: attrs[:transaction_date] || Date.current
    ).tap do |transaction|
      transaction.account = build_account_from_attributes(attrs)
      transaction.transaction_type = build_transaction_type_from_attributes(attrs)
    end
  end

  def build_account_from_attributes(attrs)
    account_name = attrs.dig(:account_attributes, :name) || attrs.dig(:account, :name)
    Account.new(name: account_name)
  end

  def build_transaction_type_from_attributes(attrs)
    type_name = attrs.dig(:transaction_type_attributes, :name).presence ||
                attrs.dig(:transaction_type, :name).presence ||
                TRANSACTION_TYPE_NAME
    TransactionType.new(name: type_name)
  end

  def should_skip_transaction?(transaction)
    transaction.account.nil? ||
      transaction.account.name.blank? ||
      transaction.amount.to_f <= 0
  end

  def persist_transaction(transaction)
    transaction.account = find_or_create_account(transaction.account)
    transaction.transaction_type = find_or_create_transaction_type(transaction.transaction_type)
    transaction.description = I18n.t('onboarding.account_setups.initial_balance_description', account_name: transaction.account.name)

    validate_and_save_transaction!(transaction)
  end

  def find_or_create_account(account)
    user.accounts.find_or_create_by!(name: account.name.to_s.strip) do |new_account|
      new_account.balance = 0.0
      new_account.saving_goal = 0.0
    end
  end

  def find_or_create_transaction_type(transaction_type)
    user.transaction_types.find_or_create_by!(kind: transaction_type.kind || TRANSACTION_TYPE_KIND) do |tt|
      tt.name = transaction_type.name || TRANSACTION_TYPE_NAME
      tt.budget_goal = 0.0
    end
  end

  def validate_and_save_transaction!(transaction)
    if transaction.invalid?
      promote_errors(transaction.errors.messages)
      raise ActiveRecord::RecordInvalid, transaction
    end

    transaction.save!
  end

  def at_least_one_valid_transaction
    valid_transactions = transactions.select do |transaction|
      account_name = transaction.account&.name
      account_name.present? && transaction.amount.to_f > 0
    end

    if valid_transactions.empty?
      errors.add(:base, I18n.t('onboarding.account_setups.errors.at_least_one_transaction'))
    end
  end
end
