# frozen_string_literal: true

module Onboarding
  class ProgressComponent < Ui::ProgressComponent
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
      %w[financial_goal personal_info account_setup]
    end

    def step_label(step)
      I18n.t("onboarding.progress.#{step}", default: step.humanize)
    end
  end
end
