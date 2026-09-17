# frozen_string_literal: true

module Marketing
  # @label Calculator
  class CalculatorComponentPreview < ViewComponent::Preview
    # The savings projection, in the current locale
    def default
      render Marketing::CalculatorComponent.new
    end

    # The same section in French
    def french
      render_with_template
    end
  end
end
