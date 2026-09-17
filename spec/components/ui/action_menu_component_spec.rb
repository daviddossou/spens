# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::ActionMenuComponent, type: :component do
  let(:rendered) do
    render_inline(described_class.new(label: "More actions")) do
      '<a class="header-menu__item" href="/debts/1/edit">Edit</a>'.html_safe
    end
  end

  it "renders a details disclosure with the trigger and the panel" do
    details = rendered.at_css("details.header-menu")
    expect(details).to be_present
    expect(details.at_css("summary.header-menu__trigger")["aria-label"]).to eq("More actions")
    expect(details.at_css(".header-menu__panel a.header-menu__item")["href"]).to eq("/debts/1/edit")
  end

  it "falls back to the dots icon when no trigger slot is given" do
    svg = rendered.at_css("summary svg")
    expect(svg["aria-hidden"]).to eq("true")
    expect(svg["fill"]).to eq("currentColor")
    expect(svg.css("circle").size).to eq(3)
  end

  it "renders a custom trigger instead of the icon" do
    rendered = render_inline(described_class.new(label: "Menu")) do |menu|
      menu.with_trigger { "Options" }
      "panel"
    end
    expect(rendered.at_css("summary").text.strip).to eq("Options")
    expect(rendered.css("summary svg")).to be_empty
  end

  it "appends extra classes and honours custom trigger and panel classes" do
    rendered = render_inline(described_class.new(
      label: "Menu", classes: "budget-scope__menu", trigger_class: "scope__trigger", panel_class: "scope__panel"
    )) { "panel" }
    expect(rendered.at_css("details")["class"]).to eq("header-menu budget-scope__menu")
    expect(rendered.at_css("summary")["class"]).to eq("scope__trigger")
    expect(rendered.at_css("summary + div")["class"]).to eq("scope__panel")
  end
end
