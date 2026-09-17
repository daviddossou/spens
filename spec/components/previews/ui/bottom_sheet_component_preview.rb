# frozen_string_literal: true

module Ui
  # @label Bottom Sheet
  class BottomSheetComponentPreview < ViewComponent::Preview
    # The closed shell mounted once per layout; a modal-frame link opens it
    def default
      render(Ui::BottomSheetComponent.new)
    end
  end
end
