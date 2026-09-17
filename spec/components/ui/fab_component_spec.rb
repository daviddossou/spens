# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::FabComponent, type: :component do
  it "renders a modal link with the label as accessible name" do
    rendered = render_inline(described_class.new(url: "/transactions/new", label: "Add a transaction"))
    link = rendered.at_css("a.fab")
    expect(link["href"]).to eq("/transactions/new")
    expect(link["aria-label"]).to eq("Add a transaction")
    expect(link["data-turbo-frame"]).to eq("modal")
    expect(link["class"]).to eq("fab")
  end

  it "draws the plus icon by default, hidden from assistive tech" do
    rendered = render_inline(described_class.new(url: "/x", label: "Add"))
    svg = rendered.at_css("svg.fab__icon")
    expect(svg["aria-hidden"]).to eq("true")
    expect(svg.at_css("path")["d"]).to eq(described_class::ICONS[:plus])
  end

  it "draws the bolt icon and falls back to plus for unknown icons" do
    bolt = render_inline(described_class.new(url: "/x", label: "Quick", icon: :bolt))
    expect(bolt.at_css("path")["d"]).to eq(described_class::ICONS[:bolt])

    unknown = render_inline(described_class.new(url: "/x", label: "Quick", icon: :star))
    expect(unknown.at_css("path")["d"]).to eq(described_class::ICONS[:plus])
  end

  it "stacks as a secondary FAB" do
    rendered = render_inline(described_class.new(url: "/x", label: "Quick", secondary: true))
    expect(rendered.at_css("a")["class"]).to eq("fab fab--secondary")
  end

  it "renders no aria-label when no label is given" do
    rendered = render_inline(described_class.new(url: "/x"))
    expect(rendered.at_css("a")["aria-label"]).to be_nil
  end
end
