# frozen_string_literal: true

module Marketing
  # @label Guide download
  class GuideDownloadComponentPreview < ViewComponent::Preview
    PDF = { url: "/guide-spens.pdf", filename: "Guide-Spens-Apprendre-a-epargner.pdf" }.freeze

    # The hero button
    def hero
      render Marketing::GuideDownloadComponent.new(url: PDF[:url], filename: PDF[:filename], label: I18n.t("guide.hero.cta"),
                                                   placement: "hero", classes: "landing-btn-light guide-btn-download")
    end

    # The larger button of the final section
    def final
      render Marketing::GuideDownloadComponent.new(url: PDF[:url], filename: PDF[:filename], label: I18n.t("guide.final.cta"),
                                                   placement: "final", classes: "landing-btn-light landing-btn-light--lg guide-btn-download")
    end
  end
end
