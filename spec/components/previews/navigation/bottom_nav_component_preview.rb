# frozen_string_literal: true

module Navigation
  # @label Bottom Nav
  class BottomNavComponentPreview < ViewComponent::Preview
    # Dashboard active
    def default
      render(Navigation::BottomNavComponent.new(current_path: "/dashboard"))
    end

    # Any tab, picked from the path
    # @param current_path select { choices: [/dashboard, /budgets, /debts/1, /goals, /accounts/5] }
    def active_tab(current_path: "/budgets")
      render(Navigation::BottomNavComponent.new(current_path: current_path))
    end

    # No tab matches the path
    def no_active_tab
      render(Navigation::BottomNavComponent.new(current_path: "/spaces"))
    end
  end
end
