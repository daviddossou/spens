# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analytics::SavingsHistoryComponent, type: :component do
  before do
    stub_current_space(build_stubbed(:space, currency: "XOF"))
    travel_to Date.new(2026, 9, 17)
  end

  let(:months) { [ [ Date.new(2026, 7, 1), 20_000.0 ], [ Date.new(2026, 8, 1), 30_000.0 ], [ Date.new(2026, 9, 1), 15_000.0 ] ] }
  let(:streak) { 3 }
  let(:any_account) { true }
  let(:set_aside) { double("any_account?": any_account, last_three: months, streak: streak) }
  let(:rendered) { render_inline(described_class.new(set_aside: set_aside)) }
  let(:columns) { rendered.css(".analyses-minimonths__col") }

  context "without a set-aside account" do
    let(:any_account) { false }

    it "renders nothing" do
      expect(rendered.to_html.strip).to be_empty
    end
  end

  it "heroes this month's net" do
    expect(rendered.at_css(".analyses-card__label").text).to eq("Set aside in September")
    expect(rendered.at_css(".analyses-hero").text).to include("15,000")
  end

  it "celebrates a streak of two months or more" do
    expect(rendered.at_css(".analyses-streak").text).to eq("3 months in a row")
  end

  context "with a single positive month" do
    let(:streak) { 1 }

    it "shows no streak" do
      expect(rendered.at_css(".analyses-streak")).to be_nil
    end
  end

  it "draws the last three months, scaled to the biggest, the current one marked" do
    expect(rendered.at_css(".analyses-minimonths")["aria-hidden"]).to eq("true")
    heights = columns.map { |c| c.at_css(".analyses-minimonths__bar")["style"][/height: (\d+)%/, 1] }
    expect(heights).to eq([ "67", "100", "50" ])
    current = columns.map { |c| c.at_css(".analyses-minimonths__bar")["class"].include?("analyses-minimonths__bar--current") }
    expect(current).to eq([ false, false, true ])
    expect(columns.map { |c| c.at_css(".analyses-minimonths__label").text }).to eq([ "July", "Augu", "Sept" ])
  end

  context "with a withdrawal month" do
    let(:months) { [ [ Date.new(2026, 7, 1), -10_000.0 ], [ Date.new(2026, 8, 1), 20_000.0 ], [ Date.new(2026, 9, 1), 0.0 ] ] }
    let(:streak) { 0 }

    it "keeps a visible floor and sizes by magnitude" do
      heights = columns.map { |c| c.at_css(".analyses-minimonths__bar")["style"][/height: (\d+)%/, 1] }
      expect(heights).to eq([ "50", "100", "8" ])
    end
  end

  context "when nothing moved" do
    let(:months) { [ [ Date.new(2026, 7, 1), 0.0 ], [ Date.new(2026, 8, 1), 0.0 ], [ Date.new(2026, 9, 1), 0.0 ] ] }
    let(:streak) { 0 }

    it "shows the floor everywhere" do
      heights = columns.map { |c| c.at_css(".analyses-minimonths__bar")["style"][/height: (\d+)%/, 1] }
      expect(heights).to eq(%w[8 8 8])
    end
  end
end
