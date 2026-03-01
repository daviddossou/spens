# frozen_string_literal: true

module Ui
  # @label Stat Card
  class StatCardComponentPreview < ViewComponent::Preview
    # Default stat card
    # ----
    # A standard stat card showing a monetary value with no trend
    def default
      render(Ui::StatCardComponent.new(
        label: "Total Balance",
        value: 1_250_000,
        currency: "XOF"
      ))
    end

    # Positive trend
    # ----
    # A stat card with a positive trend (green value)
    def positive_trend
      render(Ui::StatCardComponent.new(
        label: "Saved This Month",
        value: 150_000,
        currency: "XOF",
        trend: :positive
      ))
    end

    # Negative trend
    # ----
    # A stat card with a negative trend (red value)
    def negative_trend
      render(Ui::StatCardComponent.new(
        label: "I Owe",
        value: 500_000,
        currency: "XOF",
        trend: :negative
      ))
    end

    # Zero value
    # ----
    # A stat card displaying a zero balance
    def zero_value
      render(Ui::StatCardComponent.new(
        label: "Owed to Me",
        value: 0,
        currency: "XOF"
      ))
    end

    # Small value (below abbreviation threshold)
    # ----
    # A stat card with a value below 1,000 shown in full
    def small_value
      render(Ui::StatCardComponent.new(
        label: "Today's Spending",
        value: 750,
        currency: "XOF",
        trend: :negative
      ))
    end

    # Large value (abbreviated)
    # ----
    # A stat card with a large value shown abbreviated (e.g. 2.5M)
    def large_value
      render(Ui::StatCardComponent.new(
        label: "Total Balance",
        value: 2_500_000,
        currency: "XOF",
        trend: :positive
      ))
    end

    # Grid layout (4 cards)
    # ----
    # Four stat cards in a 2-column grid, as displayed on the dashboard
    def grid_layout
      render_with_template(
        template: "ui/stat_card_component_preview/grid_layout"
      )
    end
  end
end
