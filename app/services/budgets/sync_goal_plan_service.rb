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
      remaining = @goal.remaining.to_f

      if @goal.deadline.blank? || remaining <= 0
        retire(line)
        return line
      end

      months = months_until(@goal.deadline)
      monthly = (remaining / months).round(2)
      return retire(line) if monthly <= 0

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

    # Months from this month through the deadline month, inclusive (min 1).
    def months_until(deadline)
      start = Date.current.beginning_of_month
      target = deadline.beginning_of_month
      [ (target.year - start.year) * 12 + (target.month - start.month) + 1, 1 ].max
    end
  end
end
