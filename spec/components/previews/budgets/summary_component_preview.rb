# frozen_string_literal: true

module Budgets
  # @label Summary
  class SummaryComponentPreview < ViewComponent::Preview
    # The plan: planned savings and the in/out flow
    def plan
      render_summary(mode: :plan)
    end

    # Live: the projection with off-plan spending dragging it down
    def live
      render_summary(mode: :live, hero_value: 25_000, offplan_net: -5_000)
    end

    # Wrap-up with nothing off plan
    def wrap_up_on_plan
      render_summary(mode: :wrap_up, hero_value: 25_000, offplan_net: 0)
    end

    # Wrap-up with off-plan money
    def wrap_up_off_plan
      render_summary(mode: :wrap_up, hero_value: 20_000, offplan_net: -5_000)
    end

    # A month that loses money
    def negative
      render_summary(mode: :live, hero_value: -10_000, offplan_net: -40_000)
    end

    # Part of the savings promised to a goal
    def committed_to_goals
      render_summary(mode: :plan, committed_to_goals: 10_000, free_value: 20_000)
    end

    private

    def render_summary(mode:, hero_value: 30_000, offplan_net: 0, committed_to_goals: 0, free_value: hero_value - committed_to_goals)
      component = Budgets::SummaryComponent.new(
        actual_net: 25_000, committed_to_goals: committed_to_goals, free_value: free_value, hero_value: hero_value, mode: mode,
        offplan_net: offplan_net, planned_expense: 70_000, planned_income: 100_000, projected_net: 30_000
      )
      render_with_template(template: "shared/space_context", locals: { component: component })
    end
  end
end
