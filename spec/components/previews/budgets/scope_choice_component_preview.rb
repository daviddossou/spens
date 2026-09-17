# frozen_string_literal: true

module Budgets
  # @label Scope Choice
  class ScopeChoiceComponentPreview < ViewComponent::Preview
    # This month only vs the rule from this month on
    def default
      month_name = I18n.l(Date.current, format: "%B")
      render Budgets::ScopeChoiceComponent.new(month_name: month_name, month_prep: month_name)
    end
  end
end
