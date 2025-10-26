# frozen_string_literal: true

class Onboarding::ProgressComponentPreview < ViewComponent::Preview
  # @label Financial Goal Step
  def financial_goal
    render Onboarding::ProgressComponent.new(current_step: :financial_goal)
  end

  # @label Personal Info Step
  def personal_info
    render Onboarding::ProgressComponent.new(current_step: :personal_info)
  end

  # @label Account Setup Step
  def account_setup
    render Onboarding::ProgressComponent.new(current_step: :account_setup)
  end

  # @label Unknown / Default
  def unknown
    render Onboarding::ProgressComponent.new(current_step: :unknown)
  end
end
