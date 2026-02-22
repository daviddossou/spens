# frozen_string_literal: true

require "ostruct"

# Preview for TransactionItemComponent
#
# To view these previews in development, visit:
# http://localhost:3000/rails/view_components/transaction_item_component
#
# Available previews:
# - default: Basic transaction with customizable amount and currency
# - income_transaction: Shows positive income with green styling
# - expense_transaction: Shows negative expense with red styling
# - debt_transaction: Shows debt transaction styling
# - transfer_transaction: Shows transfer transaction styling
# - transaction_with_note: Shows transaction with note indicator
# - transaction_without_account: Shows transaction without account info
# - transaction_collection: Shows multiple transactions in a list
# - all_types: Shows all transaction types side by side
# - different_amounts: Shows various amount formats and currencies
class TransactionItemComponentPreview < ViewComponent::Preview
  # @param amount type: number
  # @param currency type: select :options[USD,EUR,GBP,CAD]
  def default(amount: 1000.00, currency: "USD")
    transaction = build_transaction(:income, "Salary", "Monthly salary payment", amount: amount)
    render_with_stubbed_user(transaction, currency)
  end

  # Shows an income transaction with positive amount
  def income_transaction
    transaction = build_transaction(:income, "Salary", "Monthly salary payment", amount: 2500.00)
    render_with_stubbed_user(transaction, "USD")
  end

  # Shows an expense transaction with negative amount
  def expense_transaction
    transaction = build_transaction(:expense, "Groceries", "Weekly grocery shopping", amount: 150.75)
    render_with_stubbed_user(transaction, "USD")
  end

  # Shows a debt transaction
  def debt_transaction
    transaction = build_transaction(:debt_in, "Personal Loan", "Loan from friend", amount: 500.00)
    render_with_stubbed_user(transaction, "USD")
  end

  # Shows a transfer transaction
  def transfer_transaction
    transaction = build_transaction(:transfer_in, "Bank Transfer", "Transfer from savings", amount: 1000.00)
    render_with_stubbed_user(transaction, "USD")
  end

  # Shows a transaction with a note
  def transaction_with_note
    transaction = build_transaction(:income, "Freelance Work", "Website redesign project", amount: 3500.00, note: "Client paid upfront for the entire project")
    render_with_stubbed_user(transaction, "USD")
  end

  # Shows a transaction without an account
  def transaction_without_account
    transaction = build_transaction(:expense, "Cash Payment", "Paid in cash", amount: 25.00, account: false)
    render_with_stubbed_user(transaction, "USD")
  end

  # Shows multiple transactions as a collection
  def transaction_collection
    transactions = [
      build_transaction(:income, "Salary", "Monthly salary", amount: 2500.00),
      build_transaction(:expense, "Rent", "Monthly rent payment", amount: 1200.00),
      build_transaction(:expense, "Groceries", "Weekly shopping", amount: 85.50),
      build_transaction(:debt_in, "Loan", "Personal loan", amount: 500.00),
      build_transaction(:transfer_out, "Savings", "Transfer to savings", amount: 300.00)
    ]

    render TransactionItemComponent.with_collection(transactions, transaction: :itself) do |component|
      helpers_stub = stub_current_user("USD")
      component.instance_variable_set(:@__vc_helpers, helpers_stub)
      component
    end
  end

  # Shows all transaction types side by side
  def all_types
    transactions = {
      income: build_transaction(:income, "Salary", "Monthly salary payment", amount: 2500.00),
      expense: build_transaction(:expense, "Groceries", "Weekly grocery shopping", amount: 150.75),
      debt_in: build_transaction(:debt_in, "Personal Loan", "Loan from friend", amount: 500.00),
      debt_out: build_transaction(:debt_out, "Loan Repayment", "Paying back loan", amount: 200.00),
      transfer_in: build_transaction(:transfer_in, "Savings Transfer", "From savings account", amount: 1000.00),
      transfer_out: build_transaction(:transfer_out, "Investment", "To investment account", amount: 800.00)
    }

    render_with_template locals: { transactions: transactions, currency: "USD" }
  end

  # Shows various amount formats
  def different_amounts
    transactions = [
      { label: "Large Amount", transaction: build_transaction(:income, "Bonus", "Annual bonus payment", amount: 15750.50), currency: "USD" },
      { label: "Medium Amount", transaction: build_transaction(:expense, "Rent", "Monthly rent", amount: 1200.00), currency: "USD" },
      { label: "Small Amount", transaction: build_transaction(:expense, "Coffee", "Morning coffee", amount: 4.50), currency: "USD" },
      { label: "Cents Only", transaction: build_transaction(:income, "Interest", "Bank interest", amount: 0.75), currency: "USD" },
      { label: "Round Amount", transaction: build_transaction(:expense, "Subscription", "Monthly software", amount: 50.00), currency: "USD" },
      { label: "Different Currency (EUR)", transaction: build_transaction(:expense, "Restaurant", "Dinner in Paris", amount: 75.80), currency: "EUR" },
      { label: "Different Currency (GBP)", transaction: build_transaction(:income, "Consulting", "Client payment", amount: 2400.00), currency: "GBP" }
    ]

    render_with_template locals: { transactions: transactions }
  end

  private

  def build_transaction(kind, name, description, amount:, note: nil, account: true)
    user = OpenStruct.new(id: "user-1", currency: "USD")
    transaction_type = OpenStruct.new(id: "type-1", kind: kind.to_s, name: name, user_id: user.id)
    account_obj = account ? OpenStruct.new(id: "account-1", name: "Main Account", user_id: user.id) : nil

    OpenStruct.new(
      id: SecureRandom.uuid,
      user_id: user.id,
      transaction_type_id: transaction_type.id,
      transaction_type: transaction_type,
      account_id: account_obj&.id,
      account: account_obj,
      amount: amount,
      description: description,
      note: note,
      transaction_date: Date.today,
      created_at: Time.current,
      updated_at: Time.current
    )
  end

  def render_with_stubbed_user(transaction, currency)
    render TransactionItemComponent.new(transaction: transaction) do |component|
      helpers_stub = stub_current_user(currency)
      component.instance_variable_set(:@__vc_helpers, helpers_stub)
      component
    end
  end

  def stub_current_user(currency)
    user_stub = OpenStruct.new(id: "preview-user", currency: currency)

    Object.new.tap do |helpers_stub|
      helpers_stub.define_singleton_method(:current_user) { user_stub }
      helpers_stub.define_singleton_method(:smart_format_money) do |amount, currency|
        # Simple money formatting for preview
        formatted = format("%.2f", amount.abs)
        case currency.upcase
        when "USD" then "$#{formatted}"
        when "EUR" then "€#{formatted}"
        when "GBP" then "£#{formatted}"
        when "CAD" then "CA$#{formatted}"
        else "#{currency} #{formatted}"
        end
      end
    end
  end
end
