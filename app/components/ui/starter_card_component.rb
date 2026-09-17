# frozen_string_literal: true

# A first-day starter: one tap opens the create sheet with the idea prefilled.
class Ui::StarterCardComponent < ViewComponent::Base
  ICONS = { cushion: :shield, trip: :pin, other: :plus, lent: :lend, borrowed: :borrow }.freeze

  def initialize(url:, label:, hint:, icon: :other, icon_classes: nil)
    @url = url
    @label = label
    @hint = hint
    @icon = icon
    @icon_classes = icon_classes
  end

  private

  attr_reader :url, :label, :hint, :icon_classes

  def icon_name
    ICONS.fetch(@icon.to_sym, :plus)
  end
end
