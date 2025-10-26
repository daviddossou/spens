# frozen_string_literal: true

class Onboarding::ProgressComponent < Ui::ProgressComponent
  def initialize(current_step:)
    @current_step = current_step.to_s

    super(
      current_step: @current_step,
      steps: onboarding_steps,
      css_class: 'onboarding-progress'
    )
  end

  private

  def onboarding_steps
    %w[financial_goal profile_setup account_setup]
  end

  def step_label(step)
    I18n.t(".onboarding.progress_component.#{step}")
  end
end
