# frozen_string_literal: true

# Step 3, "your first day noted": today's expenses, added one at a time through the real
# new-transaction sheet (TransactionsController), then a recap by category.
class Onboarding::FirstDaysController < OnboardingController
  RECAP_FROM = 2

  def show
    @expenses = todays_expenses.includes(:account, transaction_type: :parent).order(created_at: :desc).to_a
    @total = @expenses.sum { |expense| expense.amount.abs }
    @categories = spend_by_category
    # From two categories up the day reads better as its split than as a list.
    @recap = @categories.size >= RECAP_FROM
    @membership = current_user.memberships.find_by(space: current_space)

    track_onboarding_step_viewed(@recap ? "first_day_recap" : "first_day")
  end

  # Ends onboarding, with or without an expense ("I spent nothing today").
  def update
    current_space.update!(onboarding_current_step: "onboarding_completed")

    properties = { expenses: todays_expenses.count, skipped: todays_expenses.none? }
    track_onboarding_step_completed("first_day", properties)
    track_onboarding_completed(properties)

    redirect_to dashboard_path, status: :see_other
  rescue StandardError => e
    Rails.logger.error "Error in Onboarding::FirstDaysController#update: #{e.message}"
    redirect_to onboarding_first_days_path, alert: t("onboarding.errors.generic"), status: :see_other
  end

  private

  # By the precise category ("Provisions"), not its family: on a first day that is the word
  # the user just picked.
  def spend_by_category
    todays_expenses.group("transaction_types.name").sum(:amount)
                   .transform_values(&:abs).sort_by { |_, amount| -amount }.to_h
  end

  def todays_expenses
    current_space.transactions.joins(:transaction_type)
                 .where(transaction_date: Date.current, transaction_types: { kind: "expense" })
  end
end
