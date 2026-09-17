# frozen_string_literal: true

module Goals
  # @label Goal hero
  class HeroComponentPreview < ViewComponent::Preview
    include PreviewSpace

    # Saved of target, bar, and the remaining / months / status line
    def default
      account = build_account(name: "Savings", balance: 300_000)
      goal = build_goal(account, deadline: Date.current >> 3, created_at: 1.month.ago)
      render with_helpers(Goals::HeroComponent.new(account: account, progress: GoalProgress.new(goal)))
    end

    # Behind the calendar
    def behind
      account = build_account(name: "Savings", balance: 40_000)
      goal = build_goal(account, deadline: Date.current >> 3, created_at: 6.months.ago)
      render with_helpers(Goals::HeroComponent.new(account: account, progress: GoalProgress.new(goal)))
    end

    # Target met
    def reached
      account = build_account(name: "Savings", balance: 500_000)
      goal = build_goal(account)
      render with_helpers(Goals::HeroComponent.new(account: account, progress: GoalProgress.new(goal)))
    end

    # A target with no date
    def no_deadline
      account = build_account(name: "Savings", balance: 300_000)
      goal = build_goal(account, deadline: nil)
      render with_helpers(Goals::HeroComponent.new(account: account, progress: GoalProgress.new(goal)))
    end

    # No target: just what is saved
    def no_target
      account = build_account(name: "Savings", balance: 75_000)
      goal = build_goal(account, target_amount: nil, deadline: nil)
      render with_helpers(Goals::HeroComponent.new(account: account, progress: GoalProgress.new(goal)))
    end
  end
end
