# frozen_string_literal: true

module Ui
  # @label Progress Bar
  class ProgressBarComponentPreview < ViewComponent::Preview
    # Default classes
    # @param percentage number
    def default(percentage: 42)
      render(Ui::ProgressBarComponent.new(percentage: percentage.to_i))
    end

    # Goal card styling, settled
    def settled_goal
      render(Ui::ProgressBarComponent.new(percentage: 100, classes: "goal-card__bar", fill_class: "goal-card__bar-fill goal-card__bar-fill--settled", width: 100))
    end

    # Over budget: the value announces 130% while the bar stays full
    def over_budget
      render(Ui::ProgressBarComponent.new(percentage: 130, width: 100, classes: "budget-row__bar", fill_class: "budget-row__bar-fill budget-row__bar-fill--over", label: "Rent: 130%", value_text: "130% spent"))
    end
  end
end
