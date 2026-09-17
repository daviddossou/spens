# frozen_string_literal: true

require "rails_helper"

RSpec.describe Privacy::ConsentBannerComponent, type: :component do
  let(:pixel_enabled) { true }
  let(:consent_state) { nil }
  let(:rendered) { render_inline(described_class.new) }
  let(:banner) { rendered.at_css(".consent-banner") }

  before do
    allow(Meta).to receive(:pixel_enabled?).and_return(pixel_enabled)
    allow(vc_test_controller).to receive(:meta_consent_state).and_return(consent_state)
  end

  context "without a pixel configured" do
    let(:pixel_enabled) { false }

    it "renders nothing" do
      expect(rendered.to_html.strip).to be_empty
    end
  end

  %w[granted denied].each do |state|
    context "once consent is #{state}" do
      let(:consent_state) { state }

      it "renders nothing" do
        expect(rendered.to_html.strip).to be_empty
      end
    end
  end

  it "is a labelled, polite dialog driven by the consent controller" do
    expect(banner["data-controller"]).to eq("consent")
    expect(banner["role"]).to eq("dialog")
    expect(banner["aria-live"]).to eq("polite")
    expect(banner["aria-label"]).to eq(I18n.t("consent.aria_label"))
  end

  it "explains and links to the policy" do
    expect(banner.at_css(".consent-banner__text").text).to include(I18n.t("consent.text"))
    link = banner.at_css("a.consent-banner__link")
    expect(link["href"]).to eq("/privacy")
    expect(link.text).to eq(I18n.t("consent.privacy"))
  end

  it "offers decline and accept as plain buttons" do
    buttons = banner.css(".consent-banner__actions button")
    expect(buttons.map { |b| b["type"] }.uniq).to eq([ "button" ])
    expect(buttons.map { |b| b["data-action"] }).to eq([ "consent#decline", "consent#accept" ])
    expect(buttons.first["class"]).to include("consent-banner__btn--ghost")
    expect(buttons.map { |b| b.text }).to eq([ I18n.t("consent.decline"), I18n.t("consent.accept") ])
  end

  %i[fr en].each do |locale|
    it "reads in #{locale}" do
      I18n.with_locale(locale) do
        html = render_inline(described_class.new)
        expect(html.css(".translation_missing")).to be_empty
        expect(html.at_css(".consent-banner")["aria-label"]).to eq(I18n.t("consent.aria_label"))
      end
    end
  end
end
