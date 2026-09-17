# frozen_string_literal: true

require "rails_helper"

RSpec.describe Marketing::FooterComponent, type: :component do
  let(:links_class) { nil }
  let(:rendered) do
    render_inline(described_class.new(classes: "landing-final__footer", links_class: links_class)) do
      '<a href="/privacy">Privacy</a><a href="/terms">Terms</a>'.html_safe
    end
  end
  let(:footer) { rendered.at_css("div.landing-final__footer") }

  it "wraps the copyright for the current year" do
    travel_to Date.new(2031, 1, 5) do
      expect(footer.at_css("span").text).to eq("© 2031 Spens")
    end
  end

  it "renders the links inline when no links class is given" do
    expect(footer.css("> a").size).to eq(2)
    expect(footer.css("> div")).to be_empty
  end

  context "with a links class" do
    let(:links_class) { "guide-final__footer-links" }

    it "groups the links in their own block" do
      group = footer.at_css("> div.guide-final__footer-links")
      expect(group.css("a").map(&:text)).to eq(%w[Privacy Terms])
      expect(footer.css("> a")).to be_empty
    end
  end

  %i[fr en].each do |locale|
    it "reads in #{locale}" do
      I18n.with_locale(locale) do
        html = render_inline(described_class.new(classes: "x")) { "" }
        expect(html.css(".translation_missing")).to be_empty
        expect(html.at_css("span").text).to eq(I18n.t("landing.footer.copyright", year: Date.current.year))
      end
    end
  end
end
