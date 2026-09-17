# frozen_string_literal: true

module Marketing
  # @label Guide step
  class GuideStepComponentPreview < ViewComponent::Preview
    # A numbered step of the method
    def numbered
      step = I18n.t("guide.steps.items").first
      render Marketing::GuideStepComponent.new(title: step[:title], description: step[:desc], phase: step[:step], number: "01")
    end

    # A chapter of the thank-you page: phase only, no number
    def unnumbered
      render Marketing::GuideStepComponent.new(title: "Set your first goal", description: "Pick one thing you want and a date.", phase: "Chapter 2")
    end

    # Every step of the method in the three-column grid
    def all_steps
      render_with_template(locals: { steps: I18n.t("guide.steps.items") })
    end
  end
end
