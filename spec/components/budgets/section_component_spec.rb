# frozen_string_literal: true

require "rails_helper"

RSpec.describe Budgets::SectionComponent, type: :component do
  let(:user) { create(:user) }
  let(:space) { user.spaces.first }
  let(:rent) { create(:budget_entry, space: space, planned_amount: 30_000, budget_item: create(:budget_item, space: space, amount: 30_000, transaction_type: create(:transaction_type, space: space, name: "Rent"))) }
  let(:food) { create(:budget_entry, space: space, planned_amount: 20_000, budget_item: create(:budget_item, space: space, amount: 20_000, transaction_type: create(:transaction_type, space: space, name: "Food"))) }
  let(:entries) { [ rent, food ] }
  let(:actuals) { { rent => 30_000, food => 5_000 } }

  before { allow(vc_test_controller).to receive(:current_space).and_return(space) }

  def render_section(**opts)
    args = { actuals_by_entry: actuals, editable: true, mode: :live, section: :expense, entries: entries,
             planned: 50_000, actual: 35_000, short_month: "September" }.merge(opts)
    render_inline(described_class.new(**args))
  end

  it "titles the section and totals actual over planned in live mode" do
    rendered = render_section
    expect(rendered.at_css(".budget-section__title").text).to eq("Expenses")
    expect(rendered.at_css(".budget-section__total").text.squish).to include("35,000")
    expect(rendered.at_css(".budget-section__total").text.squish).to include("/ 50,000")
  end

  it "renders one row per entry, fed with its actual in the space currency" do
    rendered = render_section
    rows = rendered.css(".budget-row")
    expect(rows.size).to eq(2)
    expect(rows.first.at_css(".budget-row__name").text).to eq("Rent")
    expect(rows.first.at_css(".budget-row__status").text).to include("Paid")
    expect(rows.last.at_css(".budget-row__actual").text).to include("5,000")
    expect(rows.last.at_css(".budget-row__actual").text).to include("FCFA")
    expect(rendered.text).not_to include("translation missing")
  end

  it "totals only the plan in plan mode and passes the mode to the rows" do
    rendered = render_section(mode: :plan)
    expect(rendered.at_css(".budget-section__total").text.strip).to eq("50,000 FCFA")
    expect(rendered.css('[role="progressbar"]')).to be_empty
    expect(rendered.css(".budget-row__planned-only").size).to eq(2)
  end

  it "makes rows read only when the month is not editable" do
    from = create(:account, space: space, name: "Bank")
    to = create(:account, space: space, name: "Savings")
    transfer = create(:budget_entry, space: space, kind: "transfer", planned_amount: 10_000,
                                    budget_item: create(:budget_item, :transfer, space: space, from_account: from, to_account: to))
    rendered = render_section(section: :transfer, entries: [ transfer ], actuals_by_entry: {}, editable: false, planned: 10_000, actual: 0)
    expect(rendered.at_css(".budget-section__title").text).to eq("Transfers")
    expect(rendered.css("a.budget-row")).to be_empty
    expect(rendered.at_css("div.budget-row")).to be_present
  end

  it "states an empty section for the month" do
    rendered = render_section(section: :debt, entries: [], planned: 0, actual: 0)
    expect(rendered.at_css(".budget-section__title").text).to eq("Debts")
    expect(rendered.at_css(".budget-section__empty").text).to eq("No debt planned for September")
    expect(rendered.css(".budget-section__list")).to be_empty
  end
end
