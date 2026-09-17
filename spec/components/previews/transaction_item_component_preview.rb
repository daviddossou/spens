# frozen_string_literal: true

# http://localhost:3002/rails/view_components/transaction_item_component
class TransactionItemComponentPreview < ViewComponent::Preview
  include PreviewSpace

  # @param amount type: number
  def default(amount: 25_000)
    render_items(build_transaction(kind: "income", category: "Salary", amount: amount))
  end

  def income_transaction
    render_items(build_transaction(kind: "income", category: "Salary", amount: 250_000))
  end

  def expense_transaction
    render_items(build_transaction(kind: "expense", category: "Groceries", amount: 15_750))
  end

  def debt_transaction
    render_items(build_transaction(kind: "debt_in", category: "Personal loan", amount: 50_000))
  end

  def transfer_transaction
    render_items(build_transaction(kind: "transfer_in", category: "Bank transfer", amount: 100_000))
  end

  # The user's own words sit under the movement.
  def transaction_with_note
    render_items(build_transaction(kind: "income", category: "Freelance", amount: 350_000, note: "Site web pour Awa"))
  end

  def transaction_without_account
    render_items(build_transaction(kind: "expense", category: "Coffee", amount: 450, account: nil))
  end

  # A day's worth of movements, one per family.
  def transaction_collection
    render_items(
      build_transaction(kind: "income", category: "Salary", amount: 250_000),
      build_transaction(kind: "expense", category: "Rent", amount: 120_000),
      build_transaction(kind: "expense", category: "Groceries", amount: 8_550),
      build_transaction(kind: "debt_in", category: "Loan", amount: 50_000),
      build_transaction(kind: "transfer_out", category: "Savings", amount: 30_000)
    )
  end

  # Amounts from cents to millions, exact in the list.
  def different_amounts
    render_items(
      build_transaction(kind: "income", category: "Bonus", amount: 1_575_050),
      build_transaction(kind: "expense", category: "Rent", amount: 120_000),
      build_transaction(kind: "expense", category: "Coffee", amount: 450),
      build_transaction(kind: "income", category: "Interest", amount: 0.75)
    )
  end

  private

  def render_items(*transactions)
    render_with_template(template: "shared/space_context",
                         locals: { component: TransactionItemComponent.with_collection(transactions, transaction: :itself) })
  end
end
