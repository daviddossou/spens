# frozen_string_literal: true

require "rails_helper"

# The open, dated, quarterly case lives in public_ui_contracts_spec; this covers
# the rest of the contract.
RSpec.describe Budgets::RecurrenceFieldsComponent, type: :component do
  def render_fields(**opts)
    args = { frequency: "monthly", ends_on: nil, rollover: false, expense: true }.merge(opts)
    render_inline(described_class.new(**args))
  end

  context "for a monthly expense with no end (defaults)" do
    let(:rendered) { render_fields }

    it "starts collapsed with the summary targets in place" do
      expect(rendered.at_css("details.budget-modify")["open"]).to be_nil
      expect(rendered.at_css('[data-budget-line-target="summaryMain"]')).to be_present
      expect(rendered.at_css('[data-budget-line-target="summaryRollover"]')).to be_present
      expect(rendered.at_css(".budget-modify__toggle").text).to eq("Edit")
    end

    it "submits the frequency through a hidden field driven by the segments" do
      hidden = rendered.at_css('input[type="hidden"][name="budget_item[frequency]"]')
      expect(hidden["value"]).to eq("monthly")
      expect(hidden["data-budget-line-target"]).to eq("frequency")
      segs = rendered.css('button[data-budget-line-target="freqSeg"]')
      expect(segs.map { |s| s["data-frequency"] }).to eq(%w[monthly quarterly yearly])
      expect(segs.map { |s| s["data-action"] }.uniq).to eq([ "budget-line#setFrequency" ])
      expect(rendered.at_css(".seg--active")["data-frequency"]).to eq("monthly")
      expect(segs.map(&:text)).to eq(%w[Monthly Quarterly Yearly])
    end

    it "keeps the end date hidden until a dated end is picked" do
      ends = rendered.css('button[data-budget-line-target="endSeg"]')
      expect(ends.map { |b| b["data-end"] }).to eq(%w[never date])
      expect(rendered.at_css(".pill--active")["data-end"]).to eq("never")
      expect(rendered.at_css('.budget-setting__date[data-budget-line-target="endField"]')["class"]).to include("hidden")
      input = rendered.at_css('input[type="date"]')
      expect(input["name"]).to eq("budget_item[ends_on]")
      expect(input["data-budget-line-target"]).to eq("endInput")
      expect(input["data-action"]).to eq("budget-line#syncSummary")
    end

    it "offers the rollover toggle, unchecked, with a live example slot" do
      expect(rendered.at_css('input[type="hidden"][name="budget_item[rollover]"]')["value"]).to eq("0")
      box = rendered.at_css('input[type="checkbox"][name="budget_item[rollover]"]')
      expect(box["checked"]).to be_nil
      expect(box["data-budget-line-target"]).to eq("rollover")
      expect(rendered.at_css('[data-budget-line-target="rolloverExample"]')).to be_present
      expect(rendered.text).not_to include("translation missing")
    end
  end

  it "namespaces every field under the given prefix" do
    rendered = render_fields(name_prefix: "budget_entry")
    expect(rendered.css("input").map { |i| i["name"] }.uniq).to contain_exactly(
      "budget_entry[frequency]", "budget_entry[ends_on]", "budget_entry[rollover]"
    )
  end

  it "drops the rollover for non-expense lines" do
    rendered = render_fields(expense: false)
    expect(rendered.css('input[name="budget_item[rollover]"]')).to be_empty
    expect(rendered.css('[data-budget-line-target="summaryRollover"]')).to be_empty
    expect(rendered.css(".budget-modify__aside")).to be_empty
  end

  it "notes that a debt always counts as vital" do
    rendered = render_fields(expense: false, debt: true)
    expect(rendered.at_css(".budget-modify__aside").text).to eq("Counts as vital — a repayment can't be cut")
  end

  it "can keep the rollover without the example line" do
    rendered = render_fields(show_example: false)
    expect(rendered.at_css('input[type="checkbox"][name="budget_item[rollover]"]')).to be_present
    expect(rendered.css('[data-budget-line-target="rolloverExample"], [data-budget-line-target="summaryRollover"]')).to be_empty
  end
end
