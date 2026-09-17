# frozen_string_literal: true

require "rails_helper"

RSpec.describe Marketing::SectionHeaderComponent, type: :component do
  it "wraps the given intro in the section intro block" do
    rendered = render_inline(described_class.new) do
      '<div class="landing-eyebrow">Why</div><h2 class="landing-h2">Title</h2>'.html_safe
    end
    intro = rendered.at_css("div.landing-sect__intro")
    expect(intro.at_css(".landing-eyebrow").text).to eq("Why")
    expect(intro.at_css("h2.landing-h2").text).to eq("Title")
  end

  it "renders an empty intro without content" do
    rendered = render_inline(described_class.new)
    expect(rendered.at_css("div.landing-sect__intro").text.strip).to eq("")
  end
end
