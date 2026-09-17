# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analytics::SpendingSplitBarComponent, type: :component do
  let(:split) { { essential: 60_000.0, plaisir: 25_000.0, unclassified: 15_000.0 } }
  let(:rendered) { render_inline(described_class.new(split: split, total: 100_000.0)) }

  it "sizes the essential and treat segments by their share of the total" do
    expect(rendered.at_css(".analyses-splitbar__essential")["style"]).to include("width: 60.0%")
    expect(rendered.at_css(".analyses-splitbar__plaisir")["style"]).to include("width: 25.0%")
  end

  it "leaves the unclassified remainder to the bar's background" do
    expect(rendered.css(".analyses-splitbar > span").size).to eq(2)
  end

  context "when everything is essential" do
    let(:split) { { essential: 100_000.0, plaisir: 0.0, unclassified: 0.0 } }

    it "fills the bar with the essential segment" do
      expect(rendered.at_css(".analyses-splitbar__essential")["style"]).to include("width: 100.0%")
      expect(rendered.at_css(".analyses-splitbar__plaisir")["style"]).to include("width: 0.0%")
    end
  end
end
