# frozen_string_literal: true

require "rails_helper"

RSpec.describe Budgets::CategoryHeroComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  before { allow(vc_test_controller).to receive(:current_space).and_return(space) }
  let(:category) { create(:transaction_type, space: space, kind: "expense", name: "Groceries") }
  let(:budget_item) { create(:budget_item, space: space, transaction_type: category, amount: 50_000) }
  let(:entry) { create(:budget_entry, space: space, budget_item: budget_item, kind: category.kind, planned_amount: 50_000) }
  let(:total) { 20_000.0 }
  let(:progress) { Budgets::LineProgress.new(entry: entry, actual: total) }

  def render_hero(**overrides)
    args = {
      average: 0, category: category, editable: true, entry: entry, parent_progress: nil,
      progress: progress, total: total, transactions: Array.new(2), usual_day: nil,
      income: false, month_slug: "2026-09"
    }.merge(overrides)
    render_inline(described_class.new(**args))
  end

  context "with an envelope under plan" do
    let(:rendered) { render_hero }

    it "shows the month's amount against the planned amount" do
      expect(rendered.at_css(".budget-category__amount").text).to include("20,000")
      expect(rendered.at_css(".budget-category__planned").text).to include("of 50,000")
      expect(rendered.at_css(".budget-category__amount")["class"]).not_to include("--over")
    end

    it "renders an accessible gauge with the line's status word" do
      bar = rendered.at_css('[role="progressbar"]')
      expect(bar["aria-valuenow"]).to eq("40")
      expect(bar["aria-label"]).to eq("Groceries: 40%")
      expect(rendered.at_css(".budget-row__status").text).to include("In progress")
      expect(rendered.at_css(".budget-row__left-label").text).to include("30,000")
      expect(rendered.at_css(".budget-row__left-label").text).to include("left")
    end

    it "counts the transactions and offers no create button" do
      expect(rendered.at_css(".budget-category__count").text).to include("2 transactions")
      expect(rendered.css(".budget-category__create")).to be_empty
      expect(rendered.text).not_to include("translation missing")
    end
  end

  context "over budget" do
    let(:total) { 60_000.0 }

    it "flags the amount and says by how much" do
      rendered = render_hero
      expect(rendered.at_css(".budget-category__amount")["class"]).to include("budget-category__amount--over")
      expect(rendered.at_css(".budget-row__over-label").text).to include("over by 10,000")
      expect(rendered.at_css('[role="progressbar"] div')["class"]).to include("budget-row__bar-fill--over")
      expect(rendered.css(".budget-row__status--paid")).to be_empty
    end
  end

  context "fulfilled on plan" do
    let(:total) { 50_000.0 }

    it "celebrates with a check and no leftover label" do
      rendered = render_hero
      expect(rendered.at_css(".budget-row__status")["class"]).to include("budget-row__status--paid")
      expect(rendered.at_css(".budget-row__status").text).to include("✓")
      expect(rendered.at_css(".budget-row__status").text).to include("Paid")
      expect(rendered.css(".budget-row__left-label, .budget-row__over-label, .budget-category__above-label")).to be_empty
    end
  end

  context "income above plan" do
    let(:category) { create(:transaction_type, space: space, kind: "income", name: "Salary") }
    let(:total) { 60_000.0 }

    it "reads as a positive, not an overrun" do
      rendered = render_hero(income: true)
      amount = rendered.at_css(".budget-category__amount")
      expect(amount["class"]).to include("budget-category__amount--income")
      expect(amount["class"]).not_to include("--over")
      expect(amount.text).to include("+")
      expect(rendered.at_css(".budget-category__above-label").text).to include("10,000")
      expect(rendered.at_css(".budget-category__above-label").text).to include("above plan")
    end
  end

  it "marks an empty month and names the usual day" do
    rendered = render_hero(total: 0.0, progress: Budgets::LineProgress.new(entry: entry, actual: 0), transactions: [], usual_day: 5)
    expect(rendered.at_css(".budget-category__amount")["class"]).to include("budget-category__amount--empty")
    expect(rendered.at_css(".budget-category__status-line .budget-category__count").text).to include("Usually debited around the 5th")
  end

  it "shows the three-month average when there is one" do
    rendered = render_hero(average: 30_000)
    expect(rendered.at_css(".budget-category__average").text).to include("Last 3 months average")
    expect(rendered.at_css(".budget-category__average strong").text).to include("30,000")
    expect(render_hero(average: 0).css(".budget-category__average")).to be_empty
  end

  context "without an envelope" do
    it "counts transactions and offers to create one, prefilled with the average" do
      rendered = render_hero(entry: nil, progress: nil, average: 30_000)
      expect(rendered.css('[role="progressbar"]')).to be_empty
      expect(rendered.at_css(".budget-category__count").text).to include("2 transactions")
      link = rendered.at_css("a.budget-category__create")
      expect(link["href"]).to eq(new_budget_item_path(month: "2026-09", kind: "expense", transaction_type_name: "Groceries", amount: 30_000))
      expect(link["data-turbo-frame"]).to eq("modal")
      expect(link.text).to include("Create an envelope")
    end

    it "falls back to the month's total when there is no average" do
      rendered = render_hero(entry: nil, progress: nil, average: 0)
      expect(rendered.at_css("a.budget-category__create")["href"]).to include("amount=20000")
    end

    it "offers nothing on a closed month" do
      rendered = render_hero(entry: nil, progress: nil, editable: false)
      expect(rendered.css(".budget-category__create")).to be_empty
    end
  end

  context "as a child counted on its parent's line" do
    let(:parent) { create(:transaction_type, space: space, kind: "expense", name: "Food") }
    let(:category) { create(:transaction_type, space: space, kind: "expense", name: "Groceries", parent: parent) }
    let(:parent_item) { create(:budget_item, space: space, transaction_type: parent, amount: 80_000) }
    let(:parent_entry) { create(:budget_entry, space: space, budget_item: parent_item, planned_amount: 80_000) }
    let(:parent_progress) { Budgets::LineProgress.new(entry: parent_entry, actual: 90_000) }

    it "links up to the parent with its amounts and no create button" do
      rendered = render_hero(entry: nil, progress: nil, parent_progress: parent_progress)
      link = rendered.at_css("a.budget-category__parent-link")
      expect(link["href"]).to eq(category_budgets_path(id: parent.id, month: "2026-09"))
      expect(link.at_css("strong").text).to eq("Food")
      expect(link.text).to include("Counts in")
      expect(link.at_css(".budget-category__parent-amounts").text).to include("90,000")
      expect(link.at_css(".budget-category__parent-amounts")["class"]).to include("budget-category__parent-over")
      expect(rendered.css(".budget-category__create")).to be_empty
    end
  end
end
