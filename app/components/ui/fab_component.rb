# frozen_string_literal: true

class Ui::FabComponent < ViewComponent::Base
  # Line-art icon paths (drawn with the shared stroke style in the template).
  ICONS = {
    plus: "M12 4v16m8-8H4",
    bolt: "M13 10V3L4 14h7v7l9-11h-7z"
  }.freeze

  # secondary: stacks this FAB above the primary one (see .fab--secondary).
  def initialize(url:, label: nil, icon: :plus, secondary: false)
    @url = url
    @label = label
    @icon = icon
    @secondary = secondary
  end

  private

  attr_reader :url, :label

  def icon_path
    ICONS.fetch(@icon, ICONS[:plus])
  end

  def css_class
    [ "fab", ("fab--secondary" if @secondary) ].compact.join(" ")
  end
end
