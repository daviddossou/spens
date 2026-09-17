# frozen_string_literal: true

module Budgets
  # @label Vital / Comfort
  class VitalConfortComponentPreview < ViewComponent::Preview
    # The plan: one bar split vital / comfort
    def plan
      render_card(mode: :plan)
    end

    # Live: both tracked, with what is left and a daily pace
    def live
      render_card(mode: :live)
    end

    # Live, comfort overspent: no pace left
    def overspent
      render_card(mode: :live, actual_confort: 60_000, reste_a_depenser: -10_000)
    end

    private

    def render_card(mode:, actual_confort: 40_000, reste_a_depenser: 30_000)
      component = Budgets::VitalConfortComponent.new(
        actual_confort: actual_confort, actual_vital: 30_000, days_remaining: 10, planned_confort: 40_000,
        planned_expense_total: 100_000, planned_vital: 60_000, reste_a_depenser: reste_a_depenser, mode: mode
      )
      render_with_template(template: "shared/space_context", locals: { component: component })
    end
  end
end
