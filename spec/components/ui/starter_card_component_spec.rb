# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::StarterCardComponent, type: :component do
  let(:rendered) do
    render_inline(described_class.new(url: "/goals/new?goal_name=Cushion", label: "A cushion", hint: "Three months ahead", icon: :cushion))
  end

  it "links to the create sheet inside the modal frame" do
    link = rendered.at_css("a.goal-starter")
    expect(link["href"]).to eq("/goals/new?goal_name=Cushion")
    expect(link["data-turbo-frame"]).to eq("modal")
  end

  it "renders the label, the hint and a decorative chevron" do
    expect(rendered.at_css(".goal-starter__label").text).to eq("A cushion")
    expect(rendered.at_css(".goal-starter__hint").text).to eq("Three months ahead")
    expect(rendered.at_css(".goal-starter__chevron")["aria-hidden"]).to eq("true")
    expect(rendered.at_css(".goal-starter__chevron svg path")["d"]).to eq("M9 5l7 7-7 7")
  end

  it "maps the starter key to its glyph" do
    icon = rendered.at_css(".goal-starter__icon")
    expect(icon["aria-hidden"]).to eq("true")
    expect(icon.at_css("svg path")["d"]).to eq("M12 3l7 3v5c0 4.4-3 8-7 10-4-2-7-5.6-7-10V6l7-3z")
  end

  it "falls back to plus for an unknown key and appends icon classes" do
    rendered = render_inline(described_class.new(url: "/x", label: "L", hint: "H", icon: "mystery", icon_classes: "goal-starter__icon--lent"))
    icon = rendered.at_css(".goal-starter__icon")
    expect(icon["class"]).to eq("goal-starter__icon goal-starter__icon--lent")
    expect(icon.at_css("svg path")["d"]).to eq("M12 4v16m8-8H4")
  end

  it "uses the lend and borrow glyphs for debt starters" do
    lent = render_inline(described_class.new(url: "/x", label: "L", hint: "H", icon: :lent))
    expect(lent.at_css(".goal-starter__icon svg path")["d"]).to eq("M17 8l4 4-4 4M21 12H9M5 4v16")
    borrowed = render_inline(described_class.new(url: "/x", label: "L", hint: "H", icon: :borrowed))
    expect(borrowed.at_css(".goal-starter__icon svg path")["d"]).to eq("M7 8l-4 4 4 4M3 12h12M19 4v16")
  end
end
