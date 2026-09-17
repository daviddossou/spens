# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analytics::PeriodSelectorComponent, type: :component do
  let(:today) { Date.new(2026, 9, 17) }
  let(:period) { Analyses::Period.new("month", today: today) }
  let(:range) { period.range }
  let(:rendered) { render_inline(described_class.new(period: period, range: range)) }

  it "offers the four ranges as links, labelled for assistive tech" do
    nav = rendered.at_css("nav.analyses-ranges")
    expect(nav["aria-label"]).to eq("Analytics")
    links = nav.css("a.analyses-ranges__seg")
    expect(links.map(&:text)).to eq([ "Month", "3 months", "12 months", "Custom" ])
    expect(links.map { |a| a["href"] }).to eq(
      %w[month three_months twelve_months custom].map { |kind| "/analytics?range=#{kind}" }
    )
  end

  it "marks the current range" do
    active = rendered.css("a.analyses-ranges__seg--active")
    expect(active.map(&:text)).to eq([ "Month" ])
  end

  it "shows no date form for a preset range" do
    expect(rendered.at_css("form.analyses-custom")).to be_nil
  end

  context "with a custom range" do
    let(:period) { Analyses::Period.new("custom", start_date: "2026-08-01", end_date: "2026-08-20", today: today) }
    let(:form) { rendered.at_css("form.analyses-custom") }

    it "activates the custom segment" do
      expect(rendered.at_css("a.analyses-ranges__seg--active").text).to eq("Custom")
    end

    it "submits the dates back to analytics as a GET" do
      expect(form["action"]).to eq("/analytics")
      expect(form["method"]).to eq("get")
      expect(form.at_css('input[name="range"]')["value"]).to eq("custom")
      expect(form.at_css("button[type=submit]").text.strip).to eq("Apply")
    end

    it "prefills both bounds from the range with accessible labels" do
      from = form.at_css('input[name="start_date"]')
      to = form.at_css('input[name="end_date"]')
      expect(from["type"]).to eq("date")
      expect(from["value"]).to eq("2026-08-01")
      expect(from["aria-label"]).to eq("From")
      expect(to["value"]).to eq("2026-08-20")
      expect(to["aria-label"]).to eq("To")
    end
  end

  context "when custom was asked for but the dates did not parse" do
    it "keeps the form open, prefilled from the fallback month" do
      with_request_url "/analytics?range=custom" do
        expect(rendered.at_css("a.analyses-ranges__seg--active").text).to eq("Month")
        form = rendered.at_css("form.analyses-custom")
        expect(form.at_css('input[name="start_date"]')["value"]).to eq("2026-09-01")
        expect(form.at_css('input[name="end_date"]')["value"]).to eq("2026-09-30")
      end
    end

    it "echoes the typed dates back rather than the range" do
      with_request_url "/analytics?range=custom&start_date=2026-01-01&end_date=oops" do
        form = rendered.at_css("form.analyses-custom")
        expect(form.at_css('input[name="start_date"]')["value"]).to eq("2026-01-01")
        expect(form.at_css('input[name="end_date"]')["value"]).to eq("oops")
      end
    end
  end
end
