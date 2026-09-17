# frozen_string_literal: true

# The small line-art glyphs the app repeats: chevrons, arrows, the ⋯ of a menu.
# Business icons (transaction families) stay with TransactionIconService.
class Ui::IconComponent < ViewComponent::Base
  ICONS = {
    chevron_right: %(<path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/>),
    chevron_down: %(<path stroke-linecap="round" stroke-linejoin="round" d="M6 9l6 6 6-6"/>),
    chevron_left: %(<path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7"/>),
    check: %(<path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/>),
    close: %(<path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>),
    plus: %(<path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>),
    arrow_up: %(<path stroke-linecap="round" stroke-linejoin="round" d="M12 19V5M5 12l7-7 7 7"/>),
    arrow_down: %(<path stroke-linecap="round" stroke-linejoin="round" d="M12 5v14M19 12l-7 7-7-7"/>),
    refresh: %(<path stroke-linecap="round" stroke-linejoin="round" d="M4 4v5h5M20 20v-5h-5"/><path stroke-linecap="round" stroke-linejoin="round" d="M20 9a8 8 0 00-14.9-2M4 15a8 8 0 0014.9 2"/>),
    search: %(<circle cx="11" cy="11" r="7"/><path stroke-linecap="round" d="M20 20l-3.5-3.5"/>),
    shield: %(<path stroke-linecap="round" stroke-linejoin="round" d="M12 3l7 3v5c0 4.4-3 8-7 10-4-2-7-5.6-7-10V6l7-3z"/>),
    pin: %(<path stroke-linecap="round" stroke-linejoin="round" d="M12 21s7-6.3 7-11a7 7 0 10-14 0c0 4.7 7 11 7 11z"/><circle cx="12" cy="10" r="2.5"/>),
    lend: %(<path stroke-linecap="round" stroke-linejoin="round" d="M17 8l4 4-4 4M21 12H9M5 4v16"/>),
    borrow: %(<path stroke-linecap="round" stroke-linejoin="round" d="M7 8l-4 4 4 4M3 12h12M19 4v16"/>),
    wallet: %(<path stroke-linecap="round" stroke-linejoin="round" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"/>),
    archive: %(<path stroke-linecap="round" stroke-linejoin="round" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/>),
    dots: %(<circle cx="5" cy="12" r="2"/><circle cx="12" cy="12" r="2"/><circle cx="19" cy="12" r="2"/>)
  }.freeze

  FILLED = %i[dots].freeze

  def initialize(name, classes: nil, stroke_width: 2, **html_options)
    @name = name.to_sym
    @classes = classes
    @stroke_width = stroke_width
    @html_options = html_options
  end

  def call
    tag.svg(ICONS.fetch(@name).html_safe, **svg_attributes)
  end

  private

  def svg_attributes
    attrs = { viewBox: "0 0 24 24", class: @classes, aria: { hidden: true } }.merge(@html_options)
    if FILLED.include?(@name)
      attrs[:fill] = "currentColor"
    else
      attrs.merge!(fill: "none", stroke: "currentColor", "stroke-width": @stroke_width)
    end
    attrs
  end
end
