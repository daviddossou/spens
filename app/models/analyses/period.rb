# frozen_string_literal: true

module Analyses
  # The Analyses range and its comparison window. Month runs to today; 3/12
  # months are the last COMPLETE months (current excluded on both sides, per
  # the spec); a custom range compares to the same duration just before it.
  class Period
    KINDS = %w[month three_months twelve_months custom].freeze

    attr_reader :kind, :range

    def initialize(kind, start_date: nil, end_date: nil, today: Date.current)
      @kind = KINDS.include?(kind.to_s) ? kind.to_s : "month"
      @today = today
      @range = build_range(start_date, end_date)
    end

    # The previous window of the same duration; for the month, cut at the same day.
    def comparison_range
      case kind
      when "month"
        bom = range.begin << 1
        bom..[ bom + (@today.day - 1), bom.end_of_month ].min
      when "three_months"
        (range.begin << 3)..(range.begin - 1)
      when "twelve_months"
        nil # handled via 24-months-of-history rule by the query
      else
        duration = (range.end - range.begin).to_i + 1
        (range.begin - duration)..(range.begin - 1)
      end
    end

    def month? = kind == "month"
    def twelve_months? = kind == "twelve_months"

    # Plan detail blocks (overruns / within / off-plan) read one month's plan.
    def single_month?
      month? || (kind == "custom" && whole_months? && months.size == 1)
    end

    def granularity
      case kind
      when "month" then :day
      when "three_months" then :week
      when "twelve_months" then :month
      else
        days = days_total
        if days <= 31 then :day
        elsif days <= 180 then :week
        else :month
        end
      end
    end

    # A custom range gets a plan reading only when it hugs whole months.
    def whole_months?
      return true unless kind == "custom"

      range.begin == range.begin.beginning_of_month && range.end == range.end.end_of_month
    end

    def months
      (range.begin.to_date..range.end.to_date).map(&:beginning_of_month).uniq
    end

    def days_elapsed
      ([ @today, range.end ].min - range.begin).to_i + 1
    end

    def days_total
      (range.end - range.begin).to_i + 1
    end

    private

    def build_range(start_date, end_date)
      bom = @today.beginning_of_month
      case @kind
      when "month" then bom..@today.end_of_month
      when "three_months" then (bom << 3)..(bom - 1)
      when "twelve_months" then (bom << 12)..(bom - 1)
      else custom_range(start_date, end_date)
      end
    end

    def custom_range(start_date, end_date)
      from = Date.parse(start_date.to_s)
      to = Date.parse(end_date.to_s)
      from, to = to, from if from > to
      from..to
    rescue Date::Error, TypeError
      @kind = "month"
      @today.beginning_of_month..@today.end_of_month
    end
  end
end
