# frozen_string_literal: true

module Goals
  # @label Goal rhythm
  class RhythmComponentPreview < ViewComponent::Preview
    include PreviewSpace

    # The monthly amount a deadline implies
    def default
      account = build_account(name: "Savings", balance: 200_000)
      goal = build_goal(account, deadline: Date.current >> 4)
      render with_helpers(Goals::RhythmComponent.new(progress: GoalProgress.new(goal)))
    end

    # A far deadline: a small monthly amount
    def long_horizon
      account = build_account(name: "Savings", balance: 50_000)
      goal = build_goal(account, name: "Car", target_amount: 2_000_000, deadline: Date.current >> 36)
      render with_helpers(Goals::RhythmComponent.new(progress: GoalProgress.new(goal)))
    end
  end
end
