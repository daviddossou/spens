# frozen_string_literal: true

# http://localhost:3002/rails/view_components/onboarding/account_line_component
#
# The component renders one Onboarding::TransactionForm through the
# `fields_for :transactions` builder of the account setup form, exactly as
# app/views/onboarding/account_setups/_form.html.erb does.
class Onboarding::AccountLineComponentPreview < ViewComponent::Preview
  include PreviewSpace

  # @label Default
  def default
    render_lines(line)
  end

  # @label With Remove Button
  def with_remove_button
    render_lines(line(currency: "USD", can_remove: true))
  end

  # @label With Existing Values
  def with_existing_values
    render_lines(line(account_name: "Absa Bank Ghana", amount: 1500.50, currency: "EUR"))
  end

  # @label Different Currencies
  def different_currencies
    render_lines(
      line(account_name: "Wave", amount: 145_000, currency: "XOF"),
      line(account_name: "Checking", amount: 2_500, currency: "USD"),
      line(account_name: "Livret A", amount: 800, currency: "EUR")
    )
  end

  # @label Multiple Account Lines
  def multiple_account_lines
    render_lines(
      line(account_name: "Checking Account", amount: 2500, can_remove: true),
      line(account_name: "Orange Money", amount: 42_000, can_remove: true),
      line(can_remove: true)
    )
  end

  # @label With Validation Errors
  def with_validation_errors
    invalid = line(account_name: "", amount: nil)
    invalid[:transaction].validate

    render_lines(invalid)
  end

  # @label Edge Cases - Zero Amount
  def edge_case_zero_amount
    render_lines(line(account_name: "Empty wallet", amount: 0))
  end

  # @label Edge Cases - Large Amount
  def edge_case_large_amount
    render_lines(line(account_name: "Big savings", amount: 999_999_999.99))
  end

  private

  def line(account_name: "", amount: nil, currency: "XOF", can_remove: false)
    transaction = Onboarding::TransactionForm.new(space: preview_space, account_name: account_name, amount: amount)

    { transaction: transaction, currency: currency, can_remove: can_remove }
  end

  def render_lines(*lines)
    render_with_template(
      template: "onboarding/account_line_component_preview/lines",
      locals: { setup_form: Onboarding::AccountSetupForm.new(preview_space), lines: lines }
    )
  end
end
