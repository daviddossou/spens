# frozen_string_literal: true

module Ui
  # @label Revert Prompt
  class RevertPromptComponentPreview < ViewComponent::Preview
    # Reactivate a written-off debt (DELETE)
    def default
      render(Ui::RevertPromptComponent.new(
        title: "Bring Georges back?",
        subtitle: "The debt reopens exactly as it was.",
        button_text: "Reactivate",
        url: "#", method: :delete
      ))
    end

    # Revert a month's exception to its rule (POST)
    def budget_exception
      render(Ui::RevertPromptComponent.new(
        title: "Back to 50 000 FCFA",
        subtitle: "This month follows the rule again.",
        button_text: "Revert",
        url: "#", classes: "budget-scope__revert"
      ))
    end
  end
end
