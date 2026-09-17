# frozen_string_literal: true

require "rails_helper"

RSpec.describe Marketing::FeatureCardComponent, type: :component do
  let(:shots) { %w[feat-accounts feat-debts feat-budget] }
  let(:card) { { title: "Everything in one place", body: "Bank, cash and mobile money together." } }
  let(:index) { 1 }
  let(:rendered) { render_inline(described_class.new(card: card, i: index, feature_shots: shots)) }
  let(:button) { rendered.at_css("button.landing-feat") }

  it "is a collapsed, selectable card wired to the features controller" do
    expect(button["type"]).to eq("button")
    expect(button["id"]).to eq("landing-feat-1")
    expect(button["data-landing--features-target"]).to eq("card")
    expect(button["data-action"]).to eq("landing--features#select")
    expect(button["aria-expanded"]).to eq("false")
    expect(button["aria-controls"]).to eq("landing-feat-media-1")
    expect(rendered.at_css("#landing-feat-media-1")).to be_present
  end

  it "numbers itself from one, two digits wide, decoratively" do
    num = button.at_css(".landing-feat__num")
    expect(num.text).to eq("02")
    expect(num["aria-hidden"]).to eq("true")
  end

  it "shows the card copy" do
    expect(button.at_css(".landing-feat__title").text).to eq(card[:title])
    expect(button.at_css(".landing-feat__body").text).to eq(card[:body])
  end

  it "points at the shot matching its index in every format" do
    expect(button["data-poster"]).to match(%r{\A/assets/landing/feat-debts-\w+\.png\z})
    expect(button["data-webm"]).to include("landing/feat-debts")
    expect(button["data-webm"]).to end_with(".webm")
    expect(button["data-mp4"]).to end_with(".mp4")
  end

  it "keeps the video lazy, silent and named" do
    video = button.at_css("video")
    expect(video["data-landing--features-target"]).to eq("cardVideo")
    expect(video["preload"]).to eq("none")
    expect(video.attributes.keys).to include("muted", "loop", "playsinline")
    expect(video["aria-label"]).to eq(card[:title])
    expect(video["src"]).to be_nil
  end

  context "as the first card" do
    let(:index) { 0 }

    it "is numbered 01 and uses the first shot" do
      expect(button.at_css(".landing-feat__num").text).to eq("01")
      expect(button["data-poster"]).to include("feat-accounts")
    end
  end

  it "renders every translated card in both locales" do
    %i[fr en].each do |locale|
      I18n.with_locale(locale) do
        cards = I18n.t("landing.features.cards")
        html = render_inline(described_class.new(card: cards.last, i: cards.size - 1, feature_shots: Array.new(cards.size, "feat-goals")))
        expect(html.css(".translation_missing")).to be_empty
        expect(html.at_css(".landing-feat__title").text).to eq(cards.last[:title])
      end
    end
  end
end
