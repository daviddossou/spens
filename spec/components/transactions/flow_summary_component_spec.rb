# frozen_string_literal: true

require "rails_helper"

RSpec.describe Transactions::FlowSummaryComponent, type: :component do
  let(:rendered) { render_inline(described_class.new(currency: "EUR", money_in: 2_500, money_out: 1_200.5)) }

  it "labels both cells with the current month" do
    month = I18n.l(Date.current, format: :month_only)
    expect(rendered.at_css(".flow-cell--in .flow-cell__head").text).to include("In · #{month}")
    expect(rendered.at_css(".flow-cell--out .flow-cell__head").text).to include("Out · #{month}")
  end

  it "formats both amounts in the given currency" do
    expect(rendered.at_css(".flow-cell--in .flow-cell__value").text).to eq("2,500 €")
    expect(rendered.at_css(".flow-cell--out .flow-cell__value").text).to eq("1,200.50 €")
  end

  it "hides the arrows from assistive tech" do
    expect(rendered.css(".flow-cell__icon").map { |i| i["aria-hidden"] }).to eq([ "true", "true" ])
    expect(rendered.css(".flow-cell__icon svg").size).to eq(2)
  end
end
