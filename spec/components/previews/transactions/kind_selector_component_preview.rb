# frozen_string_literal: true

module Transactions
  # @label Kind selector
  class KindSelectorComponentPreview < ViewComponent::Preview
    # The four transaction families, expense selected
    def default
      render Transactions::KindSelectorComponent.new(label: "Type", options: options("expense"),
                                                     data: { turbo_frame: "transaction_form", action: "kind-switch#switch" })
    end

    # Income selected and already filled by the phrase
    def filled
      render Transactions::KindSelectorComponent.new(label: "Type", options: options("income", filled: true))
    end

    # Debt selected
    def debt
      render Transactions::KindSelectorComponent.new(label: "Type", options: options("debt"))
    end

    private

    def options(selected, filled: false)
      [ [ "expense", "Expense" ], [ "income", "Income" ], [ "transfer", "Transfer" ], [ "debt", "Debt" ] ].map do |value, label|
        { value: value, label: label, url: "#", selected: value == selected, filled: filled && value == selected }
      end
    end
  end
end
