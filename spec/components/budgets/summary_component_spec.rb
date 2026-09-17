# frozen_string_literal: true

require "rails_helper"

RSpec.describe Budgets::SummaryComponent, type: :component do
  before { allow(vc_test_controller).to receive(:current_space).and_return(nil) }

  def render_summary(**opts)
    args = { actual_net: 25_000, committed_to_goals: 0, free_value: 30_000, hero_value: 30_000, mode: :plan,
             offplan_net: 0, planned_expense: 70_000, planned_income: 100_000, projected_net: 30_000 }.merge(opts)
    render_inline(described_class.new(**args))
  end

  it "reads the plan: label suffix, signed hero and the in/out flow" do
    rendered = render_summary
    expect(rendered.at_css(".budget-hero__label").text.squish).to eq("This month's savings · planned")
    value = rendered.at_css(".budget-hero__value")
    expect(value.text).to include("+")
    expect(value.text).to include("30,000")
    expect(value["class"]).not_to include("--negative")
    expect(rendered.at_css(".budget-hero__sublabel").text).to include("100,000")
    expect(rendered.at_css(".budget-hero__sublabel").text).to include("in ·")
    expect(rendered.at_css(".budget-hero__sublabel").text).to include("70,000")
    expect(rendered.text).not_to include("translation missing")
  end

  it "reads the live month against the plan and flags negative off-plan money" do
    rendered = render_summary(mode: :live, hero_value: 25_000, offplan_net: -5_000)
    expect(rendered.at_css(".budget-hero__suffix").text).to eq("so far")
    sub = rendered.at_css(".budget-hero__sublabel")
    expect(sub.text).to include("Planned")
    expect(sub.text).to include("30,000")
    expect(sub.at_css(".budget-hero__offplan-amount").text).to include("5,000")
    expect(sub.text).to include("off-plan")
  end

  it "does not colour positive off-plan money" do
    rendered = render_summary(mode: :live, offplan_net: 5_000)
    expect(rendered.css(".budget-hero__offplan-amount")).to be_empty
    expect(rendered.at_css(".budget-hero__sublabel").text).to include("+")
  end

  it "wraps up with the on-plan figure alone when nothing moved off plan" do
    rendered = render_summary(mode: :wrap_up, hero_value: 25_000, offplan_net: 0)
    expect(rendered.at_css(".budget-hero__suffix").text).to eq("final")
    expect(rendered.at_css(".budget-hero__sublabel").text).to include("So far on plan")
    expect(rendered.at_css(".budget-hero__sublabel").text).to include("25,000")
  end

  it "wraps up with both the on-plan and off-plan figures otherwise" do
    rendered = render_summary(mode: :wrap_up, hero_value: 20_000, offplan_net: -5_000)
    sub = rendered.at_css(".budget-hero__sublabel")
    expect(sub.text).to include("On plan")
    expect(sub.text).to include("25,000")
    expect(sub.at_css(".budget-hero__offplan-amount").text).to include("5,000")
  end

  it "colours a negative hero" do
    rendered = render_summary(hero_value: -10_000)
    expect(rendered.at_css(".budget-hero__value")["class"]).to include("budget-hero__value--negative")
    expect(rendered.at_css(".budget-hero__value").text).to include("−")
  end

  it "states what is promised to goals only when something is" do
    expect(render_summary.css(".budget-hero__committed")).to be_empty
    committed = render_summary(committed_to_goals: 10_000, free_value: 20_000).at_css(".budget-hero__committed")
    expect(committed.css("strong").map(&:text)).to eq([ "10,000 FCFA", "20,000 FCFA" ])
    expect(committed.text).to include("promised to your goals")
  end
end
