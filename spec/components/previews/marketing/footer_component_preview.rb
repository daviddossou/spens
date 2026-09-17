# frozen_string_literal: true

module Marketing
  # @label Footer
  class FooterComponentPreview < ViewComponent::Preview
    # The landing footer: links inline after the copyright
    def landing
      render Marketing::FooterComponent.new(classes: "landing-final__footer") do
        safe_join([
          link("Privacy", "/privacy"), link("Terms", "/terms"), link("Contact", "mailto:contact@spens.me")
        ])
      end
    end

    # The guide footer: links grouped in their own block
    def guide
      render Marketing::FooterComponent.new(classes: "landing-container guide-final__footer", links_class: "guide-final__footer-links") do
        safe_join([ link("Site", "/"), link("Privacy", "/privacy") ])
      end
    end

    private

    def link(text, href)
      ActionController::Base.helpers.tag.a(text, href: href)
    end

    def safe_join(links)
      ActionController::Base.helpers.safe_join(links)
    end
  end
end
