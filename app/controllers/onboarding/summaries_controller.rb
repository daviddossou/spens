# frozen_string_literal: true

# The reward, right before the home screen: the first time the user sees their money whole.
class Onboarding::SummariesController < OnboardingController
  def show
    @accounts = current_space.accounts.active.sort_by { |account| -account.balance }
    @total = @accounts.sum(&:balance)
    @spent = current_space.transactions.joins(:transaction_type).where(transaction_types: { kind: "expense" })
                          .sum(:amount).abs
    track_onboarding_step_viewed("summary")
  end

  def update
    current_space.update!(onboarding_current_step: "onboarding_completed")
    track_onboarding_step_completed("summary")

    redirect_to dashboard_path, status: :see_other
  end
end
