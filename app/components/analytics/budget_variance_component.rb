# frozen_string_literal: true

class Analytics::BudgetVarianceComponent < ViewComponent::Base
  def initialize(period:, spending:, plan:)
    @period = period
    @spending = spending
    @plan = plan
  end

  private

  attr_reader :period, :spending, :plan

  delegate :money, to: :helpers
end
