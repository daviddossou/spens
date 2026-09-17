# frozen_string_literal: true

module Goals
  # @label Goal card
  class CardComponentPreview < ViewComponent::Preview
    include PreviewSpace

    # Saving ahead of the calendar
    def default
      render with_helpers(Goals::CardComponent.new(progress: progress(balance: 300_000)))
    end

    # Saving slower than the deadline asks
    def behind
      render with_helpers(Goals::CardComponent.new(progress: progress(balance: 40_000)))
    end

    # Target met
    def reached
      render with_helpers(Goals::CardComponent.new(progress: progress(balance: 500_000)))
    end

    # A target with no date: percentage instead of a chip
    def no_deadline
      render with_helpers(Goals::CardComponent.new(progress: progress(balance: 120_000, deadline: nil)))
    end

    # Money set aside with no target yet
    def no_target
      render with_helpers(Goals::CardComponent.new(progress: progress(balance: 75_000, target: nil, deadline: nil)))
    end

    # The list as on the goals page
    def list
      progresses = [
        progress(balance: 300_000), progress(balance: 40_000, name: "Car", target: 2_000_000),
        progress(balance: 500_000, name: "Laptop"), progress(balance: 75_000, name: "Someday", target: nil, deadline: nil)
      ]
      components = progresses.map { |p| with_helpers(Goals::CardComponent.new(progress: p)) }
      render_with_template(locals: { components: components })
    end

    private

    def progress(balance:, name: "Trip to Dakar", target: 500_000, deadline: Date.current >> 6)
      account = build_account(name: "Savings", balance: balance)
      GoalProgress.new(build_goal(account, name: name, target_amount: target, deadline: deadline, created_at: 6.months.ago))
    end
  end
end
