# frozen_string_literal: true

require "rails_helper"

RSpec.describe Debts::HeroComponent, type: :component do
  let(:debt) { build_stubbed(:debt, name: "Myri", total_lent: 100_000, total_reimbursed: 25_000) }

  def render_hero(debt, currency: "XOF")
    render_inline(described_class.new(debt: debt, currency: currency))
  end

  it "names who owes whom for a loan and shows the remaining balance" do
    rendered = render_hero(debt)
    expect(rendered.at_css(".debt-hero")["class"]).to include("debt-hero--lent")
    expect(rendered.at_css(".debt-hero__label").text).to eq("Myri owes you")
    expect(rendered.at_css(".debt-hero__amount").text).to include("75,000")
    expect(rendered.text).not_to include("translation missing")
  end

  it "gauges the repayment" do
    rendered = render_hero(debt)
    expect(rendered.at_css(".debt-hero__progress").text).to include("25,000")
    expect(rendered.at_css(".debt-hero__progress").text).to include("repaid of")
    expect(rendered.at_css(".debt-hero__progress").text).to include("100,000")
    expect(rendered.at_css('[role="progressbar"]')["aria-valuenow"]).to eq("25")
    expect(rendered.at_css(".debt-hero__pct").text).to eq("25 %")
  end

  it "flips the wording and colour for a borrowed debt" do
    rendered = render_hero(build_stubbed(:debt, :borrowed, name: "Myri"))
    expect(rendered.at_css(".debt-hero")["class"]).to include("debt-hero--borrowed")
    expect(rendered.at_css(".debt-hero__label").text).to eq("You owe Myri")
  end

  it "formats in the given currency" do
    expect(render_hero(debt, currency: "EUR").at_css(".debt-hero__amount").text).to include("€")
  end

  it "shows no gauge until an amount is set" do
    rendered = render_hero(build_stubbed(:debt, total_lent: 0, total_reimbursed: 0))
    expect(rendered.css(".debt-hero__progress, [role='progressbar']")).to be_empty
  end
end
