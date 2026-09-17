# frozen_string_literal: true

class PublicUiComponentPreview < ViewComponent::Preview
  def forms
    render_with_template
  end

  def progress
    render_with_template
  end
end
