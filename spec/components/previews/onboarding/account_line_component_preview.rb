# frozen_string_literal: true

class Onboarding::AccountLineComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render_with_form_context do |form|
      render(Onboarding::AccountLineComponent.new(
        form: form,
        index: 0,
        transaction: sample_transaction,
        currency: 'XOF',
        can_remove: false
      ))
    end
  end

  # @label With Remove Button
  def with_remove_button
    render_with_form_context do |form|
      render(Onboarding::AccountLineComponent.new(
        form: form,
        index: 1,
        transaction: sample_transaction,
        currency: 'USD',
        can_remove: true
      ))
    end
  end

  # @label With Existing Values
  def with_existing_values
    transaction = sample_transaction
    transaction.amount = 1500.50
    transaction.account.name = 'Absa Bank Ghana'

    render_with_form_context(transaction) do |form|
      render(Onboarding::AccountLineComponent.new(
        form: form,
        index: 0,
        transaction: transaction,
        currency: 'EUR',
        can_remove: false
      ))
    end
  end

  # @label Different Currencies
  def different_currencies
    render_with_form_context do |form|
      render(Onboarding::AccountLineComponent.new(
        form: form,
        index: 0,
        transaction: sample_transaction,
        currency: 'USD',
        can_remove: false
      ))
    end
  end

  # @label Multiple Account Lines
  def multiple_account_lines
    transaction = sample_transaction
    transaction.amount = 2500.00
    transaction.account.name = 'Checking Account'

    render_with_form_context(transaction) do |form|
      render(Onboarding::AccountLineComponent.new(
        form: form,
        index: 0,
        transaction: transaction,
        currency: 'XOF',
        can_remove: false
      ))
    end
  end

  # @label With Validation Errors
  def with_validation_errors
    transaction = sample_transaction
    transaction.errors.add(:amount, "can't be blank")
    transaction.account.errors.add(:name, "can't be blank")

    render_with_form_context(transaction) do |form|
      render(Onboarding::AccountLineComponent.new(
        form: form,
        index: 0,
        transaction: transaction,
        currency: 'XOF',
        can_remove: false
      ))
    end
  end

  # @label Edge Cases - Zero Amount
  def edge_case_zero_amount
    transaction = sample_transaction
    transaction.amount = 0

    render_with_form_context(transaction) do |form|
      render(Onboarding::AccountLineComponent.new(
        form: form,
        index: 0,
        transaction: transaction,
        currency: 'XOF',
        can_remove: false
      ))
    end
  end

  # @label Edge Cases - Large Amount
  def edge_case_large_amount
    transaction = sample_transaction
    transaction.amount = 999_999_999.99

    render_with_form_context(transaction) do |form|
      render(Onboarding::AccountLineComponent.new(
        form: form,
        index: 0,
        transaction: transaction,
        currency: 'XOF',
        can_remove: false
      ))
    end
  end

  private

  def render_with_form_context(transaction = nil, &block)
    # Create a form builder directly for the transaction
    transaction ||= sample_transaction
    action_view = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
    form_builder = ActionView::Helpers::FormBuilder.new(:transaction, transaction, action_view, {})

    yield form_builder
  end

  def sample_transaction
    user = User.new(id: SecureRandom.uuid, email: 'user@example.com')
    account = Account.new(name: '', user: user)
    transaction_type = TransactionType.new(
      name: Onboarding::AccountSetupForm::TRANSACTION_TYPE_NAME,
      kind: TransactionType::KIND_TRANSFER_IN,
      user: user
    )

    Transaction.new(
      amount: nil,
      description: 'Initial balance',
      transaction_date: Date.current,
      user: user,
      account: account,
      transaction_type: transaction_type
    )
  end
end
