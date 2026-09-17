# frozen_string_literal: true

class Analytics::RhythmChartComponent < ViewComponent::Base
  def initialize(period:, rhythm:)
    @period = period
    @rhythm = rhythm
  end

  private

  attr_reader :period, :rhythm

  delegate :money, to: :helpers
end
