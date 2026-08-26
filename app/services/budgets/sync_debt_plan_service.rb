# frozen_string_literal: true

module Budgets
  # When a debt has a deadline (échéance), maintain a repayment budget line that
  # spreads the remaining balance evenly over the months up to the deadline and
  # bounds it there (ends_on) — creating the line if the debt doesn't have one
  # yet. Clearing the deadline leaves any existing line unbounded and its amount
  # untouched. Completion is handled elsewhere: the debt auto-closes when fully
  # reimbursed, and EnsureEntriesService retires the line.
  class SyncDebtPlanService
    def self.call(debt) = new(debt).call

    def initialize(debt)
      @debt = debt
      @space = debt.space
    end

    def call
      line = repayment_line

      if @debt.deadline.blank?
        return line if line.nil?

        line.update!(ends_on: nil) unless line.ends_on.nil?
        RematerializeItem.call(line)
        return line
      end

      return line if @debt.remaining_balance <= 0 # nothing left to plan

      months = months_until(@debt.deadline)
      monthly = (@debt.remaining_balance / months).round(2)
      return line if monthly <= 0

      line ||= @space.budget_items.new(
        debt: @debt, kind: repayment_kind, frequency: "monthly",
        starts_on: Date.current.beginning_of_month
      )
      line.assign_attributes(
        transaction_type: nil, from_account: nil, to_account: nil,
        amount: monthly, ends_on: @debt.deadline, active: true
      )
      line.save!
      RematerializeItem.call(line)
      line
    end

    private

    # They pay me back what I lent (debt_in); I repay what I borrowed (debt_out).
    def repayment_kind
      @debt.lent? ? "debt_in" : "debt_out"
    end

    def repayment_line
      @space.budget_items.where(debt_id: @debt.id, kind: repayment_kind).order(active: :desc).first
    end

    def months_until(deadline)
      start = Date.current.beginning_of_month
      target = deadline.beginning_of_month
      [ (target.year - start.year) * 12 + (target.month - start.month) + 1, 1 ].max
    end
  end
end
