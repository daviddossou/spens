# frozen_string_literal: true

module Budgets
  # @label Month Navigation
  class MonthNavigationComponentPreview < ViewComponent::Preview
    # The current month, with the day count
    def current_month
      month = Date.current.beginning_of_month
      render Budgets::MonthNavigationComponent.new(
        day_of_month: Date.current.day, days_in_month: month.end_of_month.day,
        days_remaining: month.end_of_month.day - Date.current.day, days_until: nil, month: month, month_position: :current
      )
    end

    # A future month, counting down to it
    def future_month
      month = Date.current.beginning_of_month.next_month
      render Budgets::MonthNavigationComponent.new(
        day_of_month: nil, days_in_month: month.end_of_month.day, days_remaining: nil,
        days_until: (month - Date.current).to_i, month: month, month_position: :future
      )
    end

    # A closed month
    def past_month
      month = Date.current.beginning_of_month.prev_month
      render Budgets::MonthNavigationComponent.new(
        day_of_month: nil, days_in_month: month.end_of_month.day, days_remaining: nil,
        days_until: nil, month: month, month_position: :past
      )
    end
  end
end
