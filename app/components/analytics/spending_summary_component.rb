# frozen_string_literal: true

class Analytics::SpendingSummaryComponent < ViewComponent::Base
  def initialize(period:, spending:, range:, comparison:, plan:, split:)
    @period = period
    @spending = spending
    @range = range
    @comparison = comparison
    @plan = plan
    @split = split
  end

  private

  attr_reader :period, :spending, :range, :comparison, :plan, :split

  delegate :money, to: :helpers
end
