# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::IconComponent, type: :component do
  it "renders a stroked, decorative svg for a line icon" do
    svg = render_inline(described_class.new(:chevron_right)).at_css("svg")
    expect(svg["viewbox"]).to eq("0 0 24 24")
    expect(svg["aria-hidden"]).to eq("true")
    expect(svg["fill"]).to eq("none")
    expect(svg["stroke"]).to eq("currentColor")
    expect(svg["stroke-width"]).to eq("2")
    expect(svg.at_css("path")["d"]).to eq("M9 5l7 7-7 7")
  end

  it "renders a filled svg for the dots icon" do
    svg = render_inline(described_class.new("dots")).at_css("svg")
    expect(svg["fill"]).to eq("currentColor")
    expect(svg["stroke"]).to be_nil
    expect(svg.css("circle").size).to eq(3)
  end

  it "applies classes, stroke width and extra html attributes" do
    svg = render_inline(described_class.new(:check, classes: "row__chevron", stroke_width: 2.5, width: 20, height: 20)).at_css("svg")
    expect(svg["class"]).to eq("row__chevron")
    expect(svg["stroke-width"]).to eq("2.5")
    expect(svg["width"]).to eq("20")
    expect(svg["height"]).to eq("20")
  end

  it "renders every registered icon" do
    described_class::ICONS.each_key do |name|
      expect(render_inline(described_class.new(name)).at_css("svg")).to be_present
    end
  end

  it "raises on an unknown icon" do
    expect { render_inline(described_class.new(:unknown)) }.to raise_error(KeyError)
  end
end
