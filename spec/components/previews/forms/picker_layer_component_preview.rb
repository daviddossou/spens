# frozen_string_literal: true

module Forms
  # @label Picker Layer
  class PickerLayerComponentPreview < ViewComponent::Preview
    # The hidden shell every layout mounts once (renders nothing visible)
    def default
      render(Forms::PickerLayerComponent.new)
    end

    # The same shell forced visible to inspect its head and search
    def revealed
      render_with_template
    end
  end
end
