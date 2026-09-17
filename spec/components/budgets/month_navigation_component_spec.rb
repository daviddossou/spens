# frozen_string_literal: true

require "rails_helper"

RSpec.describe Budgets::MonthNavigationComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:month) { Date.new(2026, 9, 1) }

  def render_nav(position, **opts)
    args = { day_of_month: nil, days_in_month: 30, days_remaining: nil, days_until: nil, month: month, month_position: position }
    render_inline(described_class.new(**args.merge(opts)))
  end

  it "links to the surrounding months with accessible labels" do
    rendered = render_nav(:current, day_of_month: 17, days_remaining: 13)
    expect(rendered.at_css("nav")["aria-label"]).to eq("Change month")
    arrows = rendered.css("a.budget-month-nav__arrow")
    expect(arrows.first["href"]).to eq(budgets_path(month: "2026-08"))
    expect(arrows.first["aria-label"]).to eq("Previous month")
    expect(arrows.last["href"]).to eq(budgets_path(month: "2026-10"))
    expect(arrows.last["aria-label"]).to eq("Next month")
    expect(rendered.at_css("h2").text).to eq("September 2026")
  end

  it "describes the current month by its day count" do
    rendered = render_nav(:current, day_of_month: 17, days_remaining: 13)
    expect(rendered.at_css(".budget-month-nav__subtitle").text.strip).to eq("day 17 of 30 · 13 days left")
  end

  it "counts down to a future month" do
    expect(render_nav(:future, days_until: 14).at_css(".budget-month-nav__subtitle").text.strip).to eq("in 14 days")
    expect(render_nav(:future, days_until: 1).at_css(".budget-month-nav__subtitle").text.strip).to eq("in 1 day")
  end

  it "states a closed month" do
    rendered = render_nav(:past)
    expect(rendered.at_css(".budget-month-nav__subtitle").text.strip).to eq("month closed · 30 days")
    expect(rendered.text).not_to include("translation missing")
  end
end
