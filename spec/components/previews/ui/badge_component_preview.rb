# frozen_string_literal: true

module Ui
  # @label Badge
  class BadgeComponentPreview < ViewComponent::Preview
    # Page-styled badge (classes only, no tone)
    def default
      render(Ui::BadgeComponent.new("Owner", classes: "member-card__badge member-card__badge--owner"))
    end

    # Every generic tone
    def tones
      render_with_template
    end

    # Block content instead of the positional text
    def with_block
      render(Ui::BadgeComponent.new(tone: :info)) { "Two-way" }
    end
  end
end
