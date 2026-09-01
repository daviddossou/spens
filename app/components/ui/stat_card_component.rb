# frozen_string_literal: true

class Ui::StatCardComponent < ViewComponent::Base
  VARIANTS = %i[default hero compact].freeze

  def initialize(label:, value:, currency: nil, trend: nil, variant: :default, icon: nil,
                 sublabel: nil, footnote: nil, abbreviate: true)
    @label = label
    @value = value
    @currency = currency
    @trend = trend # :positive, :negative, :caution, or nil
    @variant = VARIANTS.include?(variant) ? variant : :default
    @icon = icon
    @sublabel = sublabel
    @footnote = footnote
    @abbreviate = abbreviate
  end

  attr_reader :label, :value, :currency, :trend, :variant, :icon, :sublabel, :footnote

  def formatted_value
    helpers.money(value, currency, compact: @abbreviate)
  end

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
    when :negative, :caution then "↓"
    end
  end
end
