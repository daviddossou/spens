# frozen_string_literal: true

require "rails_helper"

RSpec.describe Budgets::ScopeChoiceComponent, type: :component do
  let(:rendered) { render_inline(described_class.new(month_name: "september", month_prep: "september")) }

  it "offers the month and the rule as two Stimulus-driven cards" do
    cards = rendered.css("button.scope-card")
    expect(cards.size).to eq(2)
    expect(cards.map { |c| c["type"] }.uniq).to eq([ "button" ])
    expect(cards.map { |c| c["data-scope"] }).to eq(%w[month rule])
    expect(cards.map { |c| c["data-budget-scope-target"] }.uniq).to eq([ "scopeCard" ])
    expect(cards.map { |c| c["data-action"] }.uniq).to eq([ "budget-scope#setScope" ])
  end

  it "preselects the month card and names it" do
    month_card = rendered.at_css('[data-scope="month"]')
    expect(month_card["class"]).to include("scope-card--selected")
    expect(month_card.at_css(".scope-card__title").text).to eq("September")
    expect(month_card.at_css(".scope-card__sub").text).to eq("This month only")
  end

  it "describes the rule card from the month on" do
    rule_card = rendered.at_css('[data-scope="rule"]')
    expect(rule_card["class"]).not_to include("scope-card--selected")
    expect(rule_card.at_css(".scope-card__title").text).to eq("Every month")
    expect(rule_card.at_css(".scope-card__sub").text).to eq("From september")
    expect(rendered.text).not_to include("translation missing")
  end
end
