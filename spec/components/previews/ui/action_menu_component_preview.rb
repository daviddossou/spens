# frozen_string_literal: true

module Ui
  # @label Action Menu
  class ActionMenuComponentPreview < ViewComponent::Preview
    # Default: the ⋯ trigger opening a panel of links
    def default
      render_with_template
    end

    # Custom trigger text and a danger item
    def custom_trigger
      render_with_template
    end
  end
end
