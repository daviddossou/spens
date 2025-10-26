# frozen_string_literal: true

module Onboarding
  module FinancialGoals
    class SelectableCardComponent < Ui::SelectableCardComponent
      def initialize(item:, form:, model:)
        @goal = item
        @model = model

        super(
          item: @goal,
          form: form,
          field: :financial_goals,
          selected: goal_selected?
        )
      end

      private

      def goal_selected?
        Array(@model.financial_goals).include?(@goal[:key])
      end
    end
  end
end
