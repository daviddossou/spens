# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analyses::Period do
  let(:today) { Date.new(2026, 8, 18) }

  it "month runs the current month and compares to last month cut at the same day" do
    period = described_class.new("month", today: today)
    expect(period.range).to eq(Date.new(2026, 8, 1)..Date.new(2026, 8, 31))
    expect(period.comparison_range).to eq(Date.new(2026, 7, 1)..Date.new(2026, 7, 18))
    expect(period.days_elapsed).to eq(18)
    expect(period.days_total).to eq(31)
  end

  it "three months are the last complete ones, compared to the three before" do
    period = described_class.new("three_months", today: today)
    expect(period.range).to eq(Date.new(2026, 5, 1)..Date.new(2026, 7, 31))
    expect(period.comparison_range).to eq(Date.new(2026, 2, 1)..Date.new(2026, 4, 30))
  end

  it "twelve months exclude the current month and delegate their comparison" do
    period = described_class.new("twelve_months", today: today)
    expect(period.range).to eq(Date.new(2025, 8, 1)..Date.new(2026, 7, 31))
    expect(period.comparison_range).to be_nil
    expect(period.months.size).to eq(12)
  end

  it "a custom range compares to the same duration just before it" do
    period = described_class.new("custom", start_date: "2026-06-10", end_date: "2026-06-19", today: today)
    expect(period.comparison_range).to eq(Date.new(2026, 5, 31)..Date.new(2026, 6, 9))
    expect(period.whole_months?).to be(false)
  end

  it "a custom range hugging whole months earns a plan reading" do
    period = described_class.new("custom", start_date: "2026-05-01", end_date: "2026-06-30", today: today)
    expect(period.whole_months?).to be(true)
    expect(period.months).to eq([ Date.new(2026, 5, 1), Date.new(2026, 6, 1) ])
  end

  it "falls back to the month on a bad custom range" do
    period = described_class.new("custom", start_date: "nope", end_date: nil, today: today)
    expect(period.kind).to eq("month")
    expect(period.range).to eq(Date.new(2026, 8, 1)..Date.new(2026, 8, 31))
  end
end
