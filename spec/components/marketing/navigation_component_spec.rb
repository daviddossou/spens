# frozen_string_literal: true

require "rails_helper"

RSpec.describe Marketing::NavigationComponent, type: :component do
  let(:guide) { false }
  let(:rendered) do
    render_inline(described_class.new(guide: guide)) { '<a href="#feat" class="landing-nav__link">Features</a>'.html_safe }
  end
  let(:nav) { rendered.at_css("nav.landing-nav") }

  it "brands the bar with a link home" do
    brand = nav.at_css("a.landing-nav__brand")
    expect(brand["href"]).to eq("/")
    logo = brand.at_css("img.landing-nav__logo")
    expect(logo["alt"]).to eq("Spens")
    expect(logo["src"]).to match(%r{\A/assets/spens-logo-white-\w+\.png\z})
  end

  it "pushes the given links to the right of a spacer" do
    expect(nav.at_css(".landing-nav__spacer")).to be_present
    expect(nav.css(".landing-nav__spacer ~ a.landing-nav__link").map(&:text)).to eq([ "Features" ])
  end

  it "is not the guide variant by default" do
    expect(nav["class"]).to eq("landing-nav")
  end

  context "on the guide" do
    let(:guide) { true }

    it "adds the guide modifier" do
      expect(nav["class"]).to eq("landing-nav guide-nav")
    end
  end
end
