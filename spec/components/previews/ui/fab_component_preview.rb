# frozen_string_literal: true

module Ui
  # @label FAB
  class FabComponentPreview < ViewComponent::Preview
    # Primary add button
    def default
      render(Ui::FabComponent.new(url: "#", label: "Add a transaction"))
    end

    # Secondary bolt button stacked above the primary one
    def secondary_bolt
      render(Ui::FabComponent.new(url: "#", label: "Quick add", icon: :bolt, secondary: true))
    end
  end
end
