# frozen_string_literal: true

require "rails_helper"

RSpec.describe Debts::IntentCardComponent, type: :component do
  def render_card(selected:, data: { budget_debt_target: "card", kind: "debt_in", action: "click->budget-debt#selectCard" })
    render_inline(described_class.new(icon: "income", selected: selected, data: data, controller: "budget-debt"))
  end

  it "is a radio-like button carrying its Stimulus data" do
    button = render_card(selected: true).at_css("button")
    expect(button["type"]).to eq("button")
    expect(button["role"]).to eq("radio")
    expect(button["aria-checked"]).to eq("true")
    expect(button["class"]).to eq("debt-card debt-card--selected")
    expect(button["data-budget-debt-target"]).to eq("card")
    expect(button["data-kind"]).to eq("debt_in")
    expect(button["data-action"]).to eq("click->budget-debt#selectCard")
  end

  it "reads unselected without the modifier" do
    button = render_card(selected: false).at_css("button")
    expect(button["aria-checked"]).to eq("false")
    expect(button["class"]).to eq("debt-card")
  end

  it "draws the family icon and leaves title and effect to the controller" do
    rendered = render_card(selected: false)
    icon = rendered.at_css(".debt-card__icon")
    expect(icon["class"]).to include("debt-card__icon--income")
    expect(icon["aria-hidden"]).to eq("true")
    expect(icon.at_css("svg")).to be_present
    expect(rendered.at_css('.debt-card__title[data-budget-debt-target="cardTitle"]').text).to eq("")
    expect(rendered.at_css('.debt-card__effect[data-budget-debt-target="cardEffect"]').text).to eq("")
  end
end
