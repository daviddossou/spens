# frozen_string_literal: true

module Budgets
  # Keeps a goal's contribution plan in sync. When the goal has a deadline and
  # money still to save, this maintains a source-less monthly transfer budget
  # line ("put X into this account") that spreads the remaining amount evenly
  # over the months up to the deadline and stops there (ends_on). Clearing the
  # deadline, or reaching the target, retires the line.
  class SyncGoalPlanService
    def self.call(goal) = new(goal).call

    def initialize(goal)
      @goal = goal
      @account = goal.account
      @space = goal.space
    end

    def call
      line = goal_line
      monthly = GoalProgress.new(@goal).monthly

      if monthly.nil? || monthly <= 0
        retire(line)
        return line
      end

      line ||= @space.budget_items.new
      line.assign_attributes(
        kind: "transfer", from_account: nil, to_account: @account,
        transaction_type: nil, debt: nil,
        amount: monthly, frequency: "monthly",
        starts_on: Date.current.beginning_of_month,
        ends_on: @goal.deadline, active: true
      )
      line.save!
      RematerializeItem.call(line)
      line
    end

    private

    # The auto-managed savings line: a source-less transfer into this account.
    def goal_line
      @space.budget_items
            .where(kind: "transfer", to_account_id: @account.id, from_account_id: nil)
            .order(active: :desc)
            .first
    end

    def retire(line)
      return line if line.nil? || !line.active?

      line.update!(active: false)
      RematerializeItem.call(line)
      line
    end
  end
end
