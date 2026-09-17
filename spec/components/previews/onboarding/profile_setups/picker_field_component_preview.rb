# frozen_string_literal: true

module Onboarding
  module ProfileSetups
    # @label Onboarding Picker Field
    class PickerFieldComponentPreview < ViewComponent::Preview
      # Country, with a stored answer
      def default
        render_with_template locals: { field: :country, space: Space.new(country: "BJ", currency: "XOF") }
      end

      # Income frequency, unanswered
      def unanswered
        render_with_template locals: { field: :income_frequency, space: Space.new }
      end

      # The four onboarding questions together
      def all_questions
        render_with_template locals: { space: Space.new(country: "SN", currency: "XOF", income_frequency: "monthly") }
      end
    end
  end
end
