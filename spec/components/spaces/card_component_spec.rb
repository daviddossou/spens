# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spaces::CardComponent, type: :component do
  let(:space) { build_stubbed(:space, name: "Family", currency: "XOF", country: "BJ") }
  let(:active) { false }

  let(:rendered) { render_inline(described_class.new(space: space, active: active)) }

  it "opens the edit sheet in the modal frame from the name" do
    link = rendered.at_css("a.space-card__link")
    expect(link["href"]).to eq("/spaces/#{space.id}/edit")
    expect(link["data-turbo-frame"]).to eq("modal")
    expect(link.at_css(".space-card__name").text).to eq("Family")
    expect(link.at_css(".space-card__detail").text).to eq("XOF · BJ")
  end

  it "offers to switch to the space with a POST" do
    switch = rendered.at_css("a.btn")
    expect(switch.text.strip).to eq("Switch")
    expect(switch["href"]).to eq("/spaces/#{space.id}/selection")
    expect(switch["data-turbo-method"]).to eq("post")
    expect(switch["class"]).to include("btn-outline-primary", "btn-xs")
    expect(rendered.at_css(".space-card--active")).to be_nil
    expect(rendered.at_css(".space-card__active-badge")).to be_nil
  end

  it "links to the members page" do
    expect(rendered.at_css("a.space-card__members-link")["href"]).to eq("/spaces/#{space.id}/members")
  end

  context "when the space is the active one" do
    let(:active) { true }

    it "shows the active badge instead of the switch action" do
      expect(rendered.at_css(".space-card")["class"]).to include("space-card--active")
      expect(rendered.at_css(".space-card__active-badge").text).to eq("Active")
      expect(rendered.at_css("a.btn")).to be_nil
    end
  end

  context "without currency or country" do
    let(:space) { build_stubbed(:space, currency: nil, country: nil) }

    it "shows a dash" do
      expect(rendered.at_css(".space-card__detail").text).to eq("—")
    end
  end
end
