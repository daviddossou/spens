# frozen_string_literal: true

module Onboarding
  module Goals
    class GridComponent < Ui::GridComponent
      def initialize(form_builder:, model:)
        super(
          items: model.available_goals,
          columns: 2,
          gap: "1.5rem",
          min_width: "280px",
          item_component: Onboarding::Goals::GoalCardComponent,
          item_component_options: {
            form: form_builder,
            model: model
          }
        )
      end
    end
  end
end
