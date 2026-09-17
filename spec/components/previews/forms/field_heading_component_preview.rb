# frozen_string_literal: true

module Forms
  # @label Field Heading
  class FieldHeadingComponentPreview < ViewComponent::Preview
    # Label with a hint on the right
    def default
      render_with_template
    end

    # Label alone
    def label_only
      render_with_template
    end
  end
end
