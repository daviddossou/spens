# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analytics::OverrunRowComponent, type: :component do
  before { stub_current_space(build_stubbed(:space, currency: "XOF")) }

  let(:spent) { 60_000.0 }
  let(:planned) { 100_000.0 }
  let(:prorated) { 50_000.0 }
  let(:row) do
    Analyses::SpendingQuery::PlanRow.new(
      entry: double(id: "entry-1"), name: "Food", spent: spent, planned: planned, prorated: prorated,
      gap: spent - prorated, single: false, rel_gap: 0.1
    )
  end
  let(:rendered) { render_inline(described_class.new(row: row)) }
  let(:link) { rendered.at_css("a.analyses-overrun") }

  it "opens the budget entry in the modal frame" do
    expect(link["href"]).to eq("/budget_entries/entry-1/edit")
    expect(link["data-turbo-frame"]).to eq("modal")
  end

  it "names the line and states the gap as an addition" do
    expect(link.at_css(".analyses-overrun__name").text).to eq("Food")
    expect(link.at_css(".analyses-overrun__gap").text).to match(/\A\+ 10,000/)
  end

  it "fills the bar to the spent share and ticks the prorated plan" do
    expect(rendered.at_css(".analyses-bar")["class"]).to include("analyses-bar--over")
    expect(rendered.at_css(".analyses-bar__fill")["style"]).to include("width: 60.0%")
    tick = rendered.at_css(".analyses-bar__tick")
    expect(tick["style"]).to include("left: 50.0%")
    expect(tick["aria-hidden"]).to eq("true")
  end

  it "captions the spent and expected amounts" do
    caption = rendered.at_css(".analyses-row__caption").text
    expect(caption).to include("60,000")
    expect(caption).to include("50,000")
    expect(caption).to include("expected so far")
  end

  context "when spend exceeds the full plan" do
    let(:spent) { 130_000.0 }

    it "caps the fill at 100%" do
      expect(rendered.at_css(".analyses-bar__fill")["style"]).to include("width: 100%")
    end
  end

  context "when the prorated plan is the full plan (single-transaction line)" do
    let(:prorated) { planned }

    it "draws no tick" do
      expect(rendered.at_css(".analyses-bar__tick")).to be_nil
    end
  end

  context "without a planned amount" do
    let(:planned) { 0.0 }
    let(:prorated) { 0.0 }

    it "fills the whole bar and draws no tick" do
      expect(rendered.at_css(".analyses-bar__fill")["style"]).to include("width: 100%")
      expect(rendered.at_css(".analyses-bar__tick")).to be_nil
    end
  end
end
