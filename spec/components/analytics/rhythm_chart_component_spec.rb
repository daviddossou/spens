# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analytics::RhythmChartComponent, type: :component do
  before { stub_current_space(build_stubbed(:space, currency: "XOF")) }

  def unit(day, amount, future: false)
    Analyses::RhythmQuery::Unit.new(starts_on: Date.new(2026, 9, day), amount: amount, future: future)
  end

  let(:period) { Analyses::Period.new("month", today: Date.new(2026, 9, 17)) }
  let(:units) { [ unit(14, 1_000.0), unit(15, 100.0), unit(16, 5_000.0), unit(17, 0.0), unit(18, 0.0, future: true) ] }
  let(:biggest) { units[2] }
  let(:biggest_category) { "Food" }
  let(:rhythm) { double(units: units, biggest: biggest, biggest_category: biggest_category) }
  let(:rendered) { render_inline(described_class.new(period: period, rhythm: rhythm)) }
  let(:bars) { rendered.css(".analyses-rhythm__bar") }

  context "when nothing was spent" do
    let(:units) { [ unit(16, 0.0), unit(17, 0.0), unit(18, 0.0, future: true) ] }
    let(:biggest) { nil }

    it "renders nothing" do
      expect(rendered.to_html.strip).to be_empty
    end
  end

  it "titles the chart by the period's granularity" do
    expect(rendered.at_css(".analyses-card__title").text).to eq("Day by day")
  end

  it "draws one decorative bar per unit, scaled to the biggest" do
    expect(rendered.at_css(".analyses-rhythm")["aria-hidden"]).to eq("true")
    heights = bars.map { |b| b["style"][/height: ([\d.]+)%/, 1] }
    expect(heights).to eq([ "20.0", "4", "100.0", "4", "0" ])
  end

  it "greys the future and highlights the peak" do
    expect(bars.last["class"]).to include("analyses-rhythm__bar--future")
    expect(bars.map { |b| b["class"].include?("analyses-rhythm__bar--peak") }).to eq([ false, false, true, false, false ])
  end

  it "labels the axis with the first and last unit" do
    expect(rendered.css(".analyses-rhythm__axis span").map(&:text)).to eq([ "14 September", "18 September" ])
  end

  it "names the biggest day with its amount and top category" do
    caption = rendered.at_css(".analyses-row__caption")
    expect(caption.at_css("strong").text).to match(/16 September, 5,000.FCFA/)
    expect(caption.text.squish).to end_with("— Food")
  end

  context "without a top category" do
    let(:biggest_category) { nil }

    it "leaves the caption at the amount" do
      expect(rendered.at_css(".analyses-row__caption").text.squish).to end_with("FCFA")
    end
  end

  context "week by week" do
    let(:period) { Analyses::Period.new("three_months", today: Date.new(2026, 9, 17)) }
    let(:units) { [ unit(1, 20_000.0), unit(8, 35_000.0), unit(15, 12_000.0) ] }
    let(:biggest) { units[1] }

    it "switches the title and the caption wording" do
      expect(rendered.at_css(".analyses-card__title").text).to eq("Week by week")
      expect(rendered.at_css(".analyses-row__caption").text.squish).to start_with("Your biggest week: from 8 September")
    end
  end

  context "month by month" do
    let(:period) { Analyses::Period.new("twelve_months", today: Date.new(2026, 9, 17)) }
    let(:units) { [ unit(1, 200_000.0) ] }
    let(:biggest) { units[0] }

    it "names the month only" do
      expect(rendered.at_css(".analyses-card__title").text).to eq("Month by month")
      expect(rendered.at_css(".analyses-row__caption strong").text).to start_with("September, ")
    end
  end
end
