# frozen_string_literal: true

module Ui
  # @label Starter Card
  class StarterCardComponentPreview < ViewComponent::Preview
    # A goal starter
    def default
      render(Ui::StarterCardComponent.new(url: "#", label: "A cushion", hint: "Three months of expenses ahead", icon: :cushion))
    end

    # Every starter icon
    def all_icons
      render_with_template locals: { icons: Ui::StarterCardComponent::ICONS.keys }
    end

    # Debt starters coloured by direction
    def debt_starters
      render_with_template
    end
  end
end
