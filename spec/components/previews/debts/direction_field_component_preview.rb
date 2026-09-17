# frozen_string_literal: true

module Debts
  # @label Direction Field
  class DirectionFieldComponentPreview < ViewComponent::Preview
    # "I lent" preselected
    def lent
      render Debts::DirectionFieldComponent.new(direction: "lent")
    end

    # "I borrowed" preselected
    def borrowed
      render Debts::DirectionFieldComponent.new(direction: "borrowed")
    end
  end
end
