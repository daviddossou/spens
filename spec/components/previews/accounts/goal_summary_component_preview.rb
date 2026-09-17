# frozen_string_literal: true

module Accounts
  # @label Goal summary card
  class GoalSummaryComponentPreview < ViewComponent::Preview
    include PreviewSpace

    # A goal with a deadline: saved of target, bar and monthly pace
    def default
      account = build_account(name: "Savings", balance: 200_000)
      goal = build_goal(account, name: "New laptop", target_amount: 500_000, deadline: Date.current >> 4)
      render with_helpers(Accounts::GoalSummaryComponent.new(account: account, progress: GoalProgress.new(goal)))
    end

    # No deadline: no pace, just the free rhythm line
    def no_deadline
      account = build_account(name: "Savings", balance: 80_000)
      goal = build_goal(account, name: "Cushion", target_amount: 300_000, deadline: nil)
      render with_helpers(Accounts::GoalSummaryComponent.new(account: account, progress: GoalProgress.new(goal)))
    end

    # Target reached: the bar takes the settled style
    def reached
      account = build_account(name: "Savings", balance: 500_000)
      goal = build_goal(account, name: "New laptop", target_amount: 500_000)
      render with_helpers(Accounts::GoalSummaryComponent.new(account: account, progress: GoalProgress.new(goal)))
    end
  end
end
