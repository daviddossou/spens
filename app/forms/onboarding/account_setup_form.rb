# frozen_string_literal: true

class Onboarding::AccountSetupForm < BaseForm
  ##
  # Constants
  CURRENT_STEP = "onboarding_account_setup"
  NEXT_STEP = "onboarding_completed"

  ##
  # Attributes
  attr_accessor :user
  attr_reader :transaction_forms

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

    @transaction_forms =
      if payload[:transactions_attributes].present?
        build_transactions_from(payload[:transactions_attributes])
      else
        initialize_transaction
      end

    user.onboarding_current_step ||= CURRENT_STEP
  end

  def transactions
    @transaction_forms
  end

  def transactions_attributes=(attributes)
    @transaction_forms = build_transactions_from(attributes)
  end

  def submit
    return false if invalid?

    success = false

    ActiveRecord::Base.transaction do
      transaction_forms.each do |transaction_form|
        next if transaction_form.should_skip?

        result = transaction_form.submit
        unless result
          promote_errors(transaction_form.errors.messages)
          raise ActiveRecord::Rollback
        end
      end

      user.onboarding_current_step = NEXT_STEP
      user.save!
      success = true
    end

    success
  rescue StandardError => e
    Rails.logger.error "AccountSetupForm submit error: #{e.message}\n#{e.backtrace.join("\n")}"
    add_custom_error(:base, e.message)

    false
  end

  private

  def build_transactions_from(transaction_attributes)
    transaction_attributes.values.map do |attrs|
      form_attrs = {
        user: user,
        account_name: attrs[:account_name],
        amount: attrs[:amount],
        transaction_type_name: attrs[:transaction_type_name] || Onboarding::TransactionForm::DEFAULT_TRANSACTION_TYPE_NAME,
        transaction_type_kind: attrs[:transaction_type_kind] || Onboarding::TransactionForm::DEFAULT_TRANSACTION_TYPE_KIND
      }

      # Only add transaction_date if it's present, otherwise let the default kick in
      form_attrs[:transaction_date] = attrs[:transaction_date] if attrs[:transaction_date].present?

      Onboarding::TransactionForm.new(**form_attrs)
    end
  end

  def initialize_transaction
    [
      Onboarding::TransactionForm.new(
        user: user,
        account_name: "",
        amount: nil,
        transaction_date: Date.current
      )
    ]
  end

  def at_least_one_valid_transaction
    valid_forms = transaction_forms.reject(&:should_skip?)

    if valid_forms.empty?
      errors.add(:base, I18n.t("onboarding.account_setups.errors.at_least_one_transaction"))
    end
  end
end
