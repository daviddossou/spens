# frozen_string_literal: true

module Analytics
  # @label Spending split bar
  class SpendingSplitBarComponentPreview < ViewComponent::Preview
    # Essential, treat and an unclassified remainder
    def default
      render Analytics::SpendingSplitBarComponent.new(split: { essential: 60_000.0, plaisir: 25_000.0, unclassified: 15_000.0 }, total: 100_000.0)
    end

    # Everything classified
    def fully_classified
      render Analytics::SpendingSplitBarComponent.new(split: { essential: 70_000.0, plaisir: 30_000.0, unclassified: 0.0 }, total: 100_000.0)
    end

    # Mostly treats
    def mostly_treats
      render Analytics::SpendingSplitBarComponent.new(split: { essential: 20_000.0, plaisir: 75_000.0, unclassified: 5_000.0 }, total: 100_000.0)
    end
  end
end
