# frozen_string_literal: true

class Ui::StatCardComponent < ViewComponent::Base
  def initialize(label:, value:, currency: nil, trend: nil)
    @label = label
    @value = value
    @currency = currency
    @trend = trend # :positive, :negative, or nil
  end

  attr_reader :label, :value, :currency, :trend
end
