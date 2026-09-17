# frozen_string_literal: true

module Marketing
  # @label Navigation
  class NavigationComponentPreview < ViewComponent::Preview
    # The landing bar with its links
    def landing
      render Marketing::NavigationComponent.new(guide: false) do
        helpers.safe_join([
          helpers.tag.a("Features", href: "#feat", class: "landing-nav__link"),
          helpers.tag.a("Pricing", href: "#tarifs", class: "landing-nav__link"),
          helpers.tag.a("Sign up", href: "/sign_up", class: "landing-nav__cta")
        ])
      end
    end

    # The guide variant
    def guide
      render Marketing::NavigationComponent.new(guide: true) do
        helpers.safe_join([
          helpers.tag.a("Site", href: "/", class: "landing-nav__link guide-nav__link"),
          helpers.tag.a("Download", href: "#telecharger", class: "landing-nav__cta")
        ])
      end
    end

    private

    def helpers
      ActionController::Base.helpers
    end
  end
end
