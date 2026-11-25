# frozen_string_literal: true

# The PRO pill: shown wherever a Pro feature appears, from the first day, so the day it
# turns paid nobody is surprised. `floating` pins it to the corner of an icon button.
class Ui::ProBadgeComponent < ViewComponent::Base
  def initialize(floating: false)
    @floating = floating
  end

  def call
    tag.span("PRO", class: [ "pro-badge", ("pro-badge--floating" if @floating) ], aria: { hidden: true })
  end
end
