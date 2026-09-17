# frozen_string_literal: true

class Debts::DirectionFieldComponent < ViewComponent::Base
  def initialize(direction:)
    @direction = direction
  end

  private

  attr_reader :direction
end
