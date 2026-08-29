# frozen_string_literal: true

# A goal seen as progress, not just a balance. Derives everything the goal
# screens show — how much is saved against the target, the monthly rhythm the
# deadline implies, and whether that rhythm is being kept — from the Goal and
# its account. No table of its own.
#
# The monthly figure is the same one Budgets::SyncGoalPlanService spreads into
# the auto-managed savings budget line, so what the goal screen promises and
# what the budget plans stay in step.
class GoalProgress
  attr_reader :goal

  delegate :name, :account, :deadline, :target_amount, to: :goal

  def initialize(goal)
    @goal = goal
  end

  def current
    goal.current_amount
  end

  def target
    goal.target_amount.to_f
  end

  def target_set?
    goal.target_set?
  end

  # What's left to save (0 when there's no target or it's reached).
  def remaining
    goal.remaining.to_f
  end

  def percentage
    return 0 unless target.positive?

    [ [ (current / target * 100).round, 100 ].min, 0 ].max
  end

  # Reached once the remaining rounds to zero at currency precision.
  def settled?
    target_set? && remaining.round(2).zero?
  end

  def has_deadline?
    deadline.present?
  end

  # Months from this month through the deadline month, inclusive (min 1) —
  # mirrors the budget sync so the rhythm shown matches the line planned.
  def months_left
    return nil unless has_deadline?

    start = Date.current.beginning_of_month
    target_month = deadline.beginning_of_month
    [ (target_month.year - start.year) * 12 + (target_month.month - start.month) + 1, 1 ].max
  end

  # What you'd need to set aside each month to reach the target by the deadline.
  def monthly
    return nil unless has_deadline? && remaining.positive?

    (remaining / months_left).round(2)
  end

  # :reached / :on_track / :behind, or nil when there's nothing to pace against
  # (no target, or a target with no deadline).
  def status
    return :reached if settled?
    return nil unless has_deadline? && target_set?

    saved_ratio >= expected_ratio ? :on_track : :behind
  end

  private

  # Share of the target already saved.
  def saved_ratio
    return 1.0 unless target.positive?

    current / target
  end

  # Share of the way to the deadline the calendar has already travelled, from
  # the day the goal was set. On track = you've saved at least as fast as time
  # has passed.
  def expected_ratio
    span = (deadline - goal.created_at.to_date).to_f
    return 1.0 if span <= 0

    elapsed = (Date.current - goal.created_at.to_date).to_f
    [ [ elapsed / span, 1.0 ].min, 0.0 ].max
  end
end
