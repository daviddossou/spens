# frozen_string_literal: true

class Analytics::PeriodSelectorComponent < ViewComponent::Base
  def initialize(period:, range:)
    @period = period
    @range = range
  end

  private

  attr_reader :period, :range
end
