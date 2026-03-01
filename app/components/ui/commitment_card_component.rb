# frozen_string_literal: true

module Ui
  class CommitmentCardComponent < ViewComponent::Base
    attr_reader :title, :current_value, :target_value, :currency, :url

    def initialize(title:, current_value:, target_value:, currency:, url: nil)
      @title = title
      @current_value = current_value.to_f
      @target_value = target_value.to_f
      @currency = currency
      @url = url
    end

    def percentage
      return 0 if target_value.zero?
      ((current_value / target_value) * 100).round
    end

    def circumference
      2 * Math::PI * 52
    end

    def stroke_dashoffset
      circumference * (1 - [ [ percentage, 100 ].min / 100.0, 0 ].max)
    end

    def formatted_current_value
      helpers.smart_format_money(current_value, currency)
    end

    def formatted_target_value
      helpers.smart_format_money(target_value, currency)
    end
  end
end
