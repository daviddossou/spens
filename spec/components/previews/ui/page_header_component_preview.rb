# frozen_string_literal: true

module Ui
  # @label Page Header
  class PageHeaderComponentPreview < ViewComponent::Preview
    # Subtitle only, as on a sheet whose title sits in the frame
    def default
      render_with_template
    end

    # Title and subtitle with page-specific classes
    def with_title
      render_with_template
    end
  end
end
