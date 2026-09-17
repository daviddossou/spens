# frozen_string_literal: true

module Marketing
  # @label Section header
  class SectionHeaderComponentPreview < ViewComponent::Preview
    # Eyebrow, title and subtitle
    def default
      h = ActionController::Base.helpers
      render Marketing::SectionHeaderComponent.new do
        h.safe_join([
          h.tag.div("Why Spens", class: "landing-eyebrow"),
          h.tag.h2("Know where your money goes", class: "landing-h2"),
          h.tag.p("Every account, every debt, one clear picture.", class: "landing-sect__sub")
        ])
      end
    end
  end
end
