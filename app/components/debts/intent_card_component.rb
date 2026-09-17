# frozen_string_literal: true

class Debts::IntentCardComponent < ViewComponent::Base
  def initialize(icon:, selected:, data:, controller:)
    @icon = icon
    @selected = selected
    @data = data
    @controller = controller
  end

  private

  attr_reader :icon, :selected, :data, :controller

  delegate :transaction_icon_svg, to: :helpers
end
