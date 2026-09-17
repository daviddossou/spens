# frozen_string_literal: true

module Ui
  # @label Empty State
  class EmptyStateComponentPreview < ViewComponent::Preview
    # Default class with a title and a message
    def default
      render_with_template
    end

    # Page-specific classes with an icon
    def with_icon
      render_with_template
    end
  end
end
