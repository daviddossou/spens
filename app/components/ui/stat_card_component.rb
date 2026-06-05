# frozen_string_literal: true

class Ui::StatCardComponent < ViewComponent::Base
  VARIANTS = %i[default hero compact].freeze

  def initialize(label:, value:, currency: nil, trend: nil, variant: :default, icon: nil)
    @label = label
    @value = value
    @currency = currency
    @trend = trend # :positive, :negative, or nil
    @variant = VARIANTS.include?(variant) ? variant : :default
    @icon = icon
  end

  attr_reader :label, :value, :currency, :trend, :variant, :icon

  def hero?
    variant == :hero
  end

  def root_class
    [ "stat-card", ("stat-card--#{variant}" unless variant == :default) ].compact.join(" ")
  end

  # Direction glyph so trend is not communicated by color alone (WCAG).
  def trend_glyph
    case trend
    when :positive then "↑"
    when :negative then "↓"
    end
  end
end
