# frozen_string_literal: true

module Navigation
  # @label Detail Header
  class DetailHeaderComponentPreview < ViewComponent::Preview
    # Centred title with the default back label
    def default
      render(Navigation::DetailHeaderComponent.new(back_url: "#", title: "Georges"))
    end

    # Subtitle and a custom back label
    def with_subtitle
      render(Navigation::DetailHeaderComponent.new(back_url: "#", title: "Trip to Lomé", subtitle: "Savings", back_label: "Back to goals"))
    end

    # Left-aligned title
    def left_aligned
      render(Navigation::DetailHeaderComponent.new(back_url: "#", title: "Rent", align: :left))
    end

    # With a ⋯ action menu on the right
    def with_action_menu
      render_with_template
    end
  end
end
