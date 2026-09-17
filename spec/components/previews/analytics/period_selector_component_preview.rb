# frozen_string_literal: true

module Analytics
  # @label Period selector
  class PeriodSelectorComponentPreview < ViewComponent::Preview
    # The running month, no date form
    def default
      period = Analyses::Period.new("month")
      render Analytics::PeriodSelectorComponent.new(period: period, range: period.range)
    end

    # The last three complete months
    def three_months
      period = Analyses::Period.new("three_months")
      render Analytics::PeriodSelectorComponent.new(period: period, range: period.range)
    end

    # A custom range opens the from/to form
    def custom
      period = Analyses::Period.new("custom", start_date: Date.current << 2, end_date: Date.current)
      render Analytics::PeriodSelectorComponent.new(period: period, range: period.range)
    end
  end
end
