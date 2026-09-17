# frozen_string_literal: true

require "rails_helper"

RSpec.describe Pwa::InstallBannerComponent, type: :component do
  let(:rendered) { render_inline(described_class.new) }
  let(:banner) { rendered.at_css("#pwa-install-banner") }

  it "starts hidden, survives Turbo visits and belongs to the install controller" do
    expect(banner.attributes).to have_key("hidden")
    expect(banner.attributes).to have_key("data-turbo-permanent")
    expect(banner["data-controller"]).to eq("pwa-install")
  end

  it "shows the app icon decoratively with the title" do
    icon = banner.at_css("img.pwa-install__icon")
    expect(icon["src"]).to eq("/apple-touch-icon.png")
    expect(icon["alt"]).to eq("")
    expect(banner.at_css(".pwa-install__title").text).to eq(I18n.t("pwa.install.title"))
  end

  it "keeps the iOS steps hidden until the controller reveals them" do
    steps = banner.at_css(".pwa-install__ios-steps")
    expect(steps.attributes).to have_key("hidden")
    expect(steps["data-pwa-install-target"]).to eq("iosSteps")
    expect(steps.at_css("strong")).to be_present
  end

  it "ties the subtitle and the install button to the same target so both can be hidden together" do
    targets = banner.css('[data-pwa-install-target="installButton"]')
    expect(targets.size).to eq(2)
    expect(targets.first.text.strip).to eq(I18n.t("pwa.install.subtitle"))
    install = targets.last
    expect(install.name).to eq("button")
    expect(install["type"]).to eq("button")
    expect(install["data-action"]).to eq("pwa-install#install")
    expect(install["class"]).to include("pwa-install__button--primary")
  end

  it "lets the visitor dismiss it" do
    dismiss = banner.at_css('button[data-action="pwa-install#dismiss"]')
    expect(dismiss["type"]).to eq("button")
    expect(dismiss.text).to eq(I18n.t("pwa.install.not_now"))
  end

  %i[fr en].each do |locale|
    it "reads in #{locale}" do
      I18n.with_locale(locale) do
        html = render_inline(described_class.new)
        expect(html.css(".translation_missing")).to be_empty
        expect(html.at_css(".pwa-install__title").text).to eq(I18n.t("pwa.install.title"))
      end
    end
  end
end
