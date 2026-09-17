# frozen_string_literal: true

require "ostruct"
require_relative "preview_money"

module Analytics
  # @label Rhythm chart
  class RhythmChartComponentPreview < ViewComponent::Preview
    include Analytics::PreviewMoney

    # Day by day over the running month, the future greyed
    def default
      render chart("month", days_of_month)
    end

    # Week by week over three months
    def weekly
      start = (Date.current.beginning_of_month << 3).beginning_of_week
      units = 13.times.map { |i| unit(start + i * 7, [ 0, 45_000, 120_000, 80_000, 60_000 ].sample.to_f) }
      render chart("three_months", units)
    end

    # Month by month over a year
    def monthly
      start = Date.current.beginning_of_month << 12
      units = 12.times.map { |i| unit(start >> i, 200_000.0 + (i * 37_000 % 150_000)) }
      render chart("twelve_months", units)
    end

    # Nothing spent yet: nothing renders
    def empty
      units = 5.times.map { |i| unit(Date.current - 4 + i, 0.0) }
      render chart("month", units, category: nil)
    end

    private

    def unit(date, amount)
      Analyses::RhythmQuery::Unit.new(starts_on: date, amount: amount, future: date > Date.current)
    end

    def days_of_month
      bom = Date.current.beginning_of_month
      (bom..bom.end_of_month).map do |day|
        amount = day > Date.current ? 0.0 : [ 0, 2_500, 8_000, 15_000, 4_000, 31_000 ][day.day % 6].to_f
        unit(day, amount)
      end
    end

    def chart(kind, units, category: "Food")
      biggest = units.reject(&:future).max_by(&:amount)
      biggest = nil unless biggest&.amount&.positive?
      rhythm = OpenStruct.new(units: units, biggest: biggest, biggest_category: category)
      with_money(Analytics::RhythmChartComponent.new(period: Analyses::Period.new(kind), rhythm: rhythm))
    end
  end
end
