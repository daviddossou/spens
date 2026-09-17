# frozen_string_literal: true

class Budgets::MonthNavigationComponent < ViewComponent::Base
  def initialize(day_of_month:, days_in_month:, days_remaining:, days_until:, month:, month_position:)
    @day_of_month = day_of_month
    @days_in_month = days_in_month
    @days_remaining = days_remaining
    @days_until = days_until
    @month = month
    @month_position = month_position
  end

  private

  attr_reader :day_of_month, :days_in_month, :days_remaining, :days_until, :month, :month_position
end
