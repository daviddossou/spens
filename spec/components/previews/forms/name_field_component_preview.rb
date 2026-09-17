# frozen_string_literal: true

module Forms
  # @label Name Field
  class NameFieldComponentPreview < ViewComponent::Preview
    # With people chips and a "see everyone" shortcut
    def default
      render_with_template locals: { suggestions: [ "Georges", "Awa", "Mamadou" ], see_all_title: "With whom?" }
    end

    # No suggestions: a plain naming field
    def without_suggestions
      render_with_template locals: { suggestions: [], see_all_title: nil }
    end
  end
end
