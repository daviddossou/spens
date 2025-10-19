# frozen_string_literal: true

module Onboarding
  module Goals
    class GoalCardComponent < Ui::SelectableCardComponent
      def initialize(item:, form:, model:)
        @goal = item
        @model = model

        super(
          item: @goal,
          form: form,
          field: :financial_goals,
          selected: goal_selected?,
          data: {
            'financial-goals-target': 'card',
            action: 'click->onboarding--financial-goals#toggle'
          }
        )
      end

      private

      def goal_selected?
        Array(@model.financial_goals).include?(@goal[:key])
      end
    end
  end
end
