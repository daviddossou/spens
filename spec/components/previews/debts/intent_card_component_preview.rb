# frozen_string_literal: true

module Debts
  # @label Intent Card
  class IntentCardComponentPreview < ViewComponent::Preview
    # A selected card; the title and effect are filled by the Stimulus controller
    def selected
      render Debts::IntentCardComponent.new(
        icon: "income", selected: true, controller: "budget-debt",
        data: { budget_debt_target: "card", kind: "debt_in", effect: "effect_in", title: "they_repay", action: "click->budget-debt#selectCard" }
      )
    end

    # An unselected card
    def unselected
      render Debts::IntentCardComponent.new(
        icon: "expense", selected: false, controller: "budget-debt",
        data: { budget_debt_target: "card", kind: "debt_out", effect: "effect_out", title: "i_repay", action: "click->budget-debt#selectCard" }
      )
    end
  end
end
