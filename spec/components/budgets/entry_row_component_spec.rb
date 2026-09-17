# frozen_string_literal: true

require "rails_helper"

RSpec.describe Budgets::EntryRowComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:month) { Date.new(2026, 9, 1) }
  let(:category) { create(:transaction_type, space: space, kind: "expense", name: "Rent") }
  let(:budget_item) { create(:budget_item, space: space, transaction_type: category, amount: 100_000, essential: true) }
  let(:entry) { create(:budget_entry, space: space, budget_item: budget_item, planned_amount: 100_000, month: month) }

  def render_row(entry, actual: 0, **opts)
    render_inline(described_class.new(entry: entry, actual: actual, currency: "XOF", **opts))
  end

  context "an expense line in progress (live mode)" do
    let(:rendered) { render_row(entry, actual: 40_000) }

    it "opens the category detail page for the month" do
      link = rendered.at_css("a.budget-row")
      expect(link["href"]).to eq(category_budgets_path(id: category.id, month: "2026-09"))
      expect(link["class"]).to include("budget-row--link")
      expect(link["data-turbo-frame"]).to be_nil
      expect(rendered.css(".budget-row__chevron")).to be_present
    end

    it "names the line with its tag and cadence" do
      expect(rendered.at_css(".budget-row__name").text).to eq("Rent")
      expect(rendered.at_css(".budget-row__meta-line").text).to eq("Vital · Every month")
      expect(rendered.at_css(".budget-row__tag").text).to eq("Vital")
    end

    it "shows actual over planned with an accessible gauge and what is left" do
      expect(rendered.at_css(".budget-row__actual").text).to include("40,000")
      expect(rendered.at_css(".budget-row__planned").text).to include("/ 100,000")
      bar = rendered.at_css('[role="progressbar"]')
      expect(bar["aria-valuenow"]).to eq("40")
      expect(bar["aria-label"]).to eq("Rent: 40%")
      expect(rendered.at_css(".budget-row__status").text).to include("In progress")
      expect(rendered.at_css(".budget-row__left-label").text).to include("60,000")
      expect(rendered.at_css(".budget-row__left-label").text).to include("left")
      expect(rendered.text).not_to include("translation missing")
    end
  end

  it "tags a comfort line" do
    budget_item.update!(essential: false)
    expect(render_row(entry).at_css(".budget-row__meta-line").text).to include("Comfort")
  end

  it "reads Expected before any money moved" do
    rendered = render_row(entry, actual: 0)
    expect(rendered.at_css(".budget-row__status").text).to include("Expected")
    expect(rendered.at_css(".budget-row__left-label").text).to include("100,000")
  end

  it "flags an overrun without celebrating" do
    rendered = render_row(entry, actual: 120_000)
    expect(rendered.at_css(".budget-row__actual")["class"]).to include("budget-row__actual--over")
    expect(rendered.at_css(".budget-row__over-label").text).to include("over by 20,000")
    expect(rendered.at_css('[role="progressbar"] div')["class"]).to include("budget-row__bar-fill--over")
    expect(rendered.css(".budget-row__status--paid")).to be_empty
    expect(rendered.at_css('[role="progressbar"]')["aria-valuenow"]).to eq("100")
  end

  it "celebrates a line paid on plan" do
    rendered = render_row(entry, actual: 100_000)
    status = rendered.at_css(".budget-row__status")
    expect(status["class"]).to include("budget-row__status--paid")
    expect(status.text).to include("✓")
    expect(status.text).to include("Paid")
    expect(rendered.css(".budget-row__left-label, .budget-row__over-label")).to be_empty
  end

  it "mentions the carried-over part of the plan" do
    entry.update!(carried_amount: 5_000)
    expect(render_row(entry).at_css(".budget-row__carried").text).to include("incl. 5,000")
  end

  context "as a per-month exception" do
    before { entry.update!(planned_amount: 120_000, overridden: true) }

    it "shows the pill and what the rule usually plans" do
      rendered = render_row(entry)
      expect(rendered.at_css(".budget-row__exception-pill").text).to eq("This month")
      expect(rendered.at_css(".budget-row__meta-line").text).to include("usually 100,000")
      expect(rendered.at_css(".budget-row__meta-line").text).not_to include("Every month")
    end
  end

  context "in plan mode" do
    it "states only the planned amount and opens the edit sheet" do
      rendered = render_row(entry, actual: 40_000, mode: :plan)
      expect(rendered.at_css(".budget-row__planned-only").text).to include("100,000")
      expect(rendered.css(".budget-row__actual, [role='progressbar'], .budget-row__status, .budget-row__tag")).to be_empty
      link = rendered.at_css("a.budget-row")
      expect(link["href"]).to eq(edit_budget_entry_path(id: entry.id))
      expect(link["data-turbo-frame"]).to eq("modal")
    end

    it "renders a plain block when read only" do
      rendered = render_row(entry, mode: :plan, read_only: true)
      expect(rendered.css("a")).to be_empty
      expect(rendered.at_css("div.budget-row")).to be_present
    end
  end

  context "a transfer line" do
    let(:from) { create(:account, space: space, name: "Bank") }
    let(:to) { create(:account, space: space, name: "Savings") }
    let(:budget_item) { create(:budget_item, :transfer, space: space, from_account: from, to_account: to, amount: 20_000) }
    let(:entry) { create(:budget_entry, space: space, budget_item: budget_item, kind: "transfer", planned_amount: 20_000, month: month) }

    it "leads with the transfer icon and opens the edit sheet" do
      rendered = render_row(entry, actual: 20_000)
      expect(rendered.at_css(".budget-row__icon")["class"]).to include("budget-row__icon--transfer")
      expect(rendered.at_css(".budget-row__name").text).to eq("Bank → Savings")
      expect(rendered.at_css(".budget-row__meta-line").text).to eq("Every month")
      expect(rendered.css(".budget-row__tag")).to be_empty
      expect(rendered.at_css(".budget-row__status").text).to include("Transferred")
      link = rendered.at_css("a.budget-row")
      expect(link["href"]).to eq(edit_budget_entry_path(id: entry.id))
      expect(link["data-turbo-frame"]).to eq("modal")
    end

    it "is a plain block when read only" do
      rendered = render_row(entry, read_only: true)
      expect(rendered.css("a")).to be_empty
      expect(rendered.at_css("div.budget-row")).to be_present
    end
  end

  context "a debt line" do
    let(:debt) { create(:debt, space: space, name: "Georges") }

    it "reads as money to receive when they repay me" do
      item = create(:budget_item, :debt, space: space, debt: debt, kind: "debt_in", amount: 10_000)
      debt_entry = create(:budget_entry, space: space, budget_item: item, kind: "debt_in", planned_amount: 10_000, month: month)
      rendered = render_row(debt_entry, actual: 4_000)
      expect(rendered.at_css(".budget-row__icon")["class"]).to include("budget-row__icon--debt_in")
      expect(rendered.at_css(".budget-row__name").text).to eq("Georges")
      expect(rendered.at_css(".budget-row__meta-line").text).to eq("To receive · Every month")
      expect(rendered.at_css(".budget-row__actual")["class"]).to include("budget-row__amount--income")
      expect(rendered.at_css(".budget-row__left-label").text).to include("6,000")
      expect(rendered.at_css(".budget-row__left-label").text).to include("to receive")
      expect(rendered.at_css('[role="progressbar"] div')["class"]).to include("budget-row__bar-fill--income")
    end

    it "reads as money to send when I repay" do
      item = create(:budget_item, :debt, space: space, debt: debt, kind: "debt_out", amount: 10_000)
      debt_entry = create(:budget_entry, space: space, budget_item: item, kind: "debt_out", planned_amount: 10_000, month: month)
      rendered = render_row(debt_entry, actual: 4_000)
      expect(rendered.at_css(".budget-row__meta-line").text).to eq("To repay · Every month")
      expect(rendered.at_css(".budget-row__actual")["class"]).not_to include("budget-row__amount--income")
      expect(rendered.at_css(".budget-row__left-label").text).to include("to send")
    end
  end
end
