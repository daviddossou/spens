# frozen_string_literal: true

# Step 2, "your day": expenses noted one at a time through the real new-transaction sheet
# (TransactionsController), each on an account it creates along the way. Every expense of
# the space counts — the space is new, and "yesterday's, to try" is noted with its own date.
class Onboarding::FirstDaysController < OnboardingController
  def show
    @expenses = expenses.includes(:account, transaction_type: :parent).order(created_at: :desc).to_a
    @total = @expenses.sum { |expense| expense.amount.abs }
    @accounts_count = @expenses.map(&:account_id).compact.uniq.size
    @membership = current_user.memberships.find_by(space: current_space)

    track_onboarding_step_viewed("first_day")
  end

  # Moves on to the balances once at least one expense exists: the step cannot be skipped.
  def update
    return redirect_to onboarding_first_days_path, status: :see_other if expenses.none?

    current_space.update!(onboarding_current_step: "onboarding_balances")
    track_onboarding_step_completed("first_day", expenses: expenses.count, accounts: current_space.accounts.active.count)

    redirect_to onboarding_balances_path, status: :see_other
  rescue StandardError => e
    Rails.logger.error "Error in Onboarding::FirstDaysController#update: #{e.message}"
    redirect_to onboarding_first_days_path, alert: t("onboarding.errors.generic"), status: :see_other
  end

  private

  def expenses
    current_space.transactions.joins(:transaction_type).where(transaction_types: { kind: "expense" })
  end
end
