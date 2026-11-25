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
    dots: %(<circle cx="5" cy="12" r="2"/><circle cx="12" cy="12" r="2"/><circle cx="19" cy="12" r="2"/>),
    dots_vertical: %(<circle cx="12" cy="5" r="2"/><circle cx="12" cy="12" r="2"/><circle cx="12" cy="19" r="2"/>),
    download: %(<path stroke-linecap="round" stroke-linejoin="round" d="M12 4v11m0 0l-4-4m4 4l4-4M5 19h14"/>),
    share: %(<path stroke-linecap="round" stroke-linejoin="round" d="M12 3v12M8 7l4-4 4 4M8 11H6a1 1 0 00-1 1v8a1 1 0 001 1h12a1 1 0 001-1v-8a1 1 0 00-1-1h-2"/>),
photo: %(<path stroke-linecap="round" stroke-linejoin="round" d="M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 001.5-1.5V6a1.5 1.5 0 00-1.5-1.5H3.75A1.5 1.5 0 002.25 6v12a1.5 1.5 0 001.5 1.5zm10.5-11.25h.008v.008h-.008V8.25zm.375 0a.375.375 0 11-.75 0 .375.375 0 01.75 0z"/>),
camera: %(<path stroke-linecap="round" stroke-linejoin="round" d="M6.827 6.175A2.31 2.31 0 015.186 7.23c-.38.054-.757.112-1.134.175C2.999 7.58 2.25 8.507 2.25 9.574V18a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18V9.574c0-1.067-.75-1.994-1.802-2.169a47.865 47.865 0 00-1.134-.175 2.31 2.31 0 01-1.64-1.055l-.822-1.316a2.192 2.192 0 00-1.736-1.039 48.774 48.774 0 00-5.232 0 2.192 2.192 0 00-1.736 1.039l-.821 1.316z"/><path stroke-linecap="round" stroke-linejoin="round" d="M16.5 12.75a4.5 4.5 0 11-9 0 4.5 4.5 0 019 0z"/>),
sparkles: %(<path stroke-linecap="round" stroke-linejoin="round" d="M12 3l1.8 4.7L18.5 9.5l-4.7 1.8L12 16l-1.8-4.7L5.5 9.5l4.7-1.8L12 3zM5 17l.7 1.8L7.5 19.5l-1.8.7L5 22l-.7-1.8L2.5 19.5l1.8-.7L5 17z"/>),
document: %(<path stroke-linecap="round" stroke-linejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z"/>),
credit_card: %(<path stroke-linecap="round" stroke-linejoin="round" d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6 2.25h3m-3.75 3h15a2.25 2.25 0 002.25-2.25V6.75A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25v10.5A2.25 2.25 0 004.5 19.5z"/>),
    copy: %(<rect x="9" y="9" width="11" height="11" rx="2"/><path stroke-linecap="round" stroke-linejoin="round" d="M5 15V6a2 2 0 012-2h9"/>)
  }.freeze

  FILLED = %i[dots dots_vertical].freeze

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
