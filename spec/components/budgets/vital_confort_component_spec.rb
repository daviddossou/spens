# frozen_string_literal: true

require "rails_helper"

RSpec.describe Budgets::VitalConfortComponent, type: :component do
  before { allow(vc_test_controller).to receive(:current_space).and_return(nil) }

  def render_card(**opts)
    args = { actual_confort: 40_000, actual_vital: 30_000, days_remaining: 10, planned_confort: 40_000,
             planned_expense_total: 100_000, planned_vital: 60_000, reste_a_depenser: 30_000, mode: :live }.merge(opts)
    render_inline(described_class.new(**args))
  end

  context "in plan mode" do
    let(:rendered) { render_card(mode: :plan) }

    it "draws one split bar described for assistive tech" do
      bar = rendered.at_css('.vital-confort__bar[role="img"]')
      expect(bar["aria-label"]).to include("Vital 60,000")
      expect(bar["aria-label"]).to include("Comfort 40,000")
      expect(bar.at_css(".vital-confort__bar-fill--vital")["style"]).to eq("width: 60%;")
      expect(bar.at_css(".vital-confort__bar-fill--confort")["style"]).to eq("width: 40%;")
    end

    it "legends both halves and totals the plan" do
      expect(rendered.at_css(".vital-confort__title").text).to eq("Vital and comfort")
      expect(rendered.at_css(".vital-confort__total").text.squish).to include("100,000")
      expect(rendered.at_css(".vital-confort__total").text.squish).to include("of expenses")
      expect(rendered.css(".vital-confort__key strong").map(&:text)).to eq([ "60,000 FCFA", "40,000 FCFA" ])
      expect(rendered.css(".vital-confort__track, .vital-confort__footer")).to be_empty
      expect(rendered.text).not_to include("translation missing")
    end
  end

  context "in live mode" do
    let(:rendered) { render_card }

    it "tracks vital and comfort against their plans" do
      tracks = rendered.css(".vital-confort__track")
      expect(tracks.map { |t| t.at_css(".vital-confort__track-label").text }).to eq(%w[Vital Comfort])
      expect(tracks[0].at_css("strong").text).to include("30,000")
      expect(tracks[0].at_css(".vital-confort__track-planned").text).to include("/ 60,000")
      expect(tracks[0].at_css(".vital-confort__bar-fill--vital")["style"]).to eq("width: 50%;")
      expect(tracks[1].at_css(".vital-confort__bar-fill--confort")["style"]).to eq("width: 100%;")
      expect(rendered.at_css(".vital-confort__total").text.squish).to include("70,000")
      expect(rendered.at_css(".vital-confort__total").text.squish).to include("of 100,000")
      expect(rendered.css('[role="img"]')).to be_empty
    end

    it "states what is left with a daily pace" do
      expect(rendered.at_css(".vital-confort__reste-label").text).to eq("Left to spend")
      expect(rendered.at_css(".vital-confort__reste-value").text).to include("30,000")
      expect(rendered.at_css(".vital-confort__reste-rate").text).to include("3,000")
      expect(rendered.at_css(".vital-confort__reste-rate").text).to include("/day")
    end

    it "caps an overrun bar at 100% and drops the pace once overspent" do
      over = render_card(actual_confort: 60_000, reste_a_depenser: -10_000)
      expect(over.css(".vital-confort__track")[1].at_css(".vital-confort__bar-fill")["style"]).to eq("width: 100%;")
      expect(over.css(".vital-confort__reste-rate")).to be_empty
    end

    it "drops the pace on the month's last day" do
      expect(render_card(days_remaining: 0).css(".vital-confort__reste-rate")).to be_empty
    end
  end
end
