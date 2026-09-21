# frozen_string_literal: true

# The onboarding chrome: "Step 1 of 3", the step's title, one bar segment per step.
class Onboarding::StepHeaderComponent < ViewComponent::Base
  STEPS = 3

  def initialize(step:, title:)
    @step = step
    @title = title
  end

  private

  attr_reader :step, :title

  def segment_class(index)
    index <= step ? "onboarding-step-header__segment is-done" : "onboarding-step-header__segment"
  end
end
