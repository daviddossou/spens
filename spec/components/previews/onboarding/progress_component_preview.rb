# frozen_string_literal: true

module Onboarding
  class ProgressComponentPreview < ViewComponent::Preview
    # @label Financial Goal Step
    def financial_goal
      render ProgressComponent.new(current_step: :financial_goal)
    end

    # @label Personal Info Step
    def personal_info
      render ProgressComponent.new(current_step: :personal_info)
    end

    # @label Account Setup Step
    def account_setup
      render ProgressComponent.new(current_step: :account_setup)
    end

    # @label Unknown / Default
    def unknown
      render ProgressComponent.new(current_step: :unknown)
    end
  end
end
