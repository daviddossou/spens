# frozen_string_literal: true

module Ui
  # @label Commitment Card
  class CommitmentCardComponentPreview < ViewComponent::Preview
    # Default commitment card with 50% progress
    # ----
    # A standard commitment card showing a savings goal at 50% completion
    def default
      render(Ui::CommitmentCardComponent.new(
        title: "Emergency Fund",
        current_value: 500_000,
        target_value: 1_000_000,
        currency: "XOF"
      ))
    end

    # Clickable card with URL
    # ----
    # A clickable commitment card that links to a detail page
    def clickable
      render(Ui::CommitmentCardComponent.new(
        title: "Vacation Savings",
        current_value: 350_000,
        target_value: 800_000,
        currency: "XOF",
        url: "/goals/1"
      ))
    end

    # Low progress (10%)
    # ----
    # A card showing minimal progress towards the goal
    def low_progress
      render(Ui::CommitmentCardComponent.new(
        title: "New Car Fund",
        current_value: 200_000,
        target_value: 2_000_000,
        currency: "XOF"
      ))
    end

    # High progress (90%)
    # ----
    # A card showing near completion of the savings goal
    def high_progress
      render(Ui::CommitmentCardComponent.new(
        title: "Down Payment",
        current_value: 4_500_000,
        target_value: 5_000_000,
        currency: "XOF"
      ))
    end

    # Completed goal (100%)
    # ----
    # A card showing a fully completed savings goal
    def completed
      render(Ui::CommitmentCardComponent.new(
        title: "Holiday Fund",
        current_value: 750_000,
        target_value: 750_000,
        currency: "XOF"
      ))
    end

    # Over-funded (120%)
    # ----
    # A card showing savings that exceeded the original goal
    def over_funded
      render(Ui::CommitmentCardComponent.new(
        title: "Education Fund",
        current_value: 1_200_000,
        target_value: 1_000_000,
        currency: "XOF"
      ))
    end

    # Just started (0%)
    # ----
    # A card showing a newly created goal with no progress yet
    def just_started
      render(Ui::CommitmentCardComponent.new(
        title: "Wedding Fund",
        current_value: 0,
        target_value: 3_000_000,
        currency: "XOF"
      ))
    end

    # Small amounts
    # ----
    # A card with small currency values
    def small_amounts
      render(Ui::CommitmentCardComponent.new(
        title: "Coffee Fund",
        current_value: 5_000,
        target_value: 10_000,
        currency: "XOF"
      ))
    end

    # Large amounts
    # ----
    # A card with very large currency values
    def large_amounts
      render(Ui::CommitmentCardComponent.new(
        title: "House Purchase",
        current_value: 15_000_000,
        target_value: 50_000_000,
        currency: "XOF"
      ))
    end

    # Long title
    # ----
    # A card with a very long title to test text wrapping
    def long_title
      render(Ui::CommitmentCardComponent.new(
        title: "Retirement Savings Account for Future Financial Security",
        current_value: 2_500_000,
        target_value: 10_000_000,
        currency: "XOF"
      ))
    end

    # Multiple cards in a grid
    # ----
    # Shows how multiple cards look together in a grid layout
    def multiple_cards
      render_with_template(locals: {
        goals: [
          { title: "Emergency Fund", current: 500_000, target: 1_000_000 },
          { title: "Vacation", current: 300_000, target: 800_000 },
          { title: "New Car", current: 1_500_000, target: 3_000_000 },
          { title: "Wedding", current: 0, target: 2_000_000 }
        ]
      })
    end

    # Different currency (USD)
    # ----
    # A card using US dollars instead of XOF
    def usd_currency
      render(Ui::CommitmentCardComponent.new(
        title: "Investment Goal",
        current_value: 5_000,
        target_value: 10_000,
        currency: "$"
      ))
    end

    # Different currency (EUR)
    # ----
    # A card using Euros instead of XOF
    def eur_currency
      render(Ui::CommitmentCardComponent.new(
        title: "European Trip",
        current_value: 1_500,
        target_value: 3_000,
        currency: "€"
      ))
    end
  end
end
