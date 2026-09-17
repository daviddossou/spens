# frozen_string_literal: true

require "rails_helper"

RSpec.describe Budgets::UnplannedSectionComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:user) { create(:user) }
  let(:space) { user.spaces.first }

  before { allow(vc_test_controller).to receive(:current_space).and_return(space) }
  let(:month) { Date.new(2026, 9, 1) }
  let(:taxi) { create(:transaction_type, space: space, kind: "expense", name: "Taxi") }
  let(:bonus) { create(:transaction_type, space: space, kind: "income", name: "Bonus") }
  let(:bank) { create(:account, space: space, name: "Bank") }
  let(:savings) { create(:account, space: space, name: "Savings") }
  let(:unplanned) do
    { expense: { taxi => { amount: 12_000.0, prev: 3_000.0 } },
      income: { bonus => { amount: 50_000.0, prev: 0.0 } },
      transfers: [ { from: bank, to: savings, amount: 20_000.0, prev: 0.0 } ] }
  end

  def render_section(**opts)
    render_inline(described_class.new(**{ month: month, unplanned: unplanned, read_only: false }.merge(opts)))
  end

  context "on a live month" do
    let(:rendered) { render_section }

    it "heads the card with the off-plan spend and the row count" do
      expect(rendered.at_css(".hors-plan__title").text).to include("12,000")
      expect(rendered.at_css(".hors-plan__title").text).to include("spent off plan")
      expect(rendered.at_css(".hors-plan__subtitle").text).to eq("This is what's widening the gap with your plan")
      expect(rendered.at_css(".hors-plan__count").text).to eq("3")
      expect(rendered.text).not_to include("translation missing")
    end

    it "links a recurring expense to its detail and offers to plan it" do
      row = rendered.css(".hors-plan__row")[0]
      expect(row.at_css("a.hors-plan__name")["href"]).to eq(category_budgets_path(id: taxi.id, month: "2026-09"))
      expect(row.at_css(".hors-plan__meta").text.squish).to include("12,000")
      expect(row.at_css(".hors-plan__meta").text.squish).to include("also in August")
      action = row.at_css("a.hors-plan__action")
      expect(action.text).to eq("Plan it")
      expect(action["href"]).to eq(new_budget_item_path(month: "2026-09", kind: "expense", transaction_type_name: "Taxi", amount: 12_000))
      expect(action["data-turbo-frame"]).to eq("modal")
    end

    it "signs an income seen once and plans it as income" do
      row = rendered.css(".hors-plan__row")[1]
      expect(row.at_css(".hors-plan__meta").text.squish).to include("+")
      expect(row.at_css(".hors-plan__meta").text.squish).to include("seen once")
      expect(row.at_css("a.hors-plan__action")["href"]).to include("kind=income")
      expect(row.at_css("a.hors-plan__action")["href"]).to include("transaction_type_name=Bonus")
    end

    it "states a transfer without link or action" do
      row = rendered.css(".hors-plan__row")[2]
      expect(row.at_css("span.hors-plan__name").text).to eq("Bank → Savings")
      expect(row.css("a")).to be_empty
    end
  end

  it "only reads on a closed month" do
    rendered = render_section(read_only: true)
    expect(rendered.at_css(".hors-plan__subtitle").text).to eq("This is what widened the gap with your plan")
    expect(rendered.css(".hors-plan__action")).to be_empty
    expect(rendered.css("a.hors-plan__name").size).to eq(2)
  end

  it "renders nothing when everything is on plan" do
    rendered = render_section(unplanned: { expense: {}, income: {}, transfers: [] })
    expect(rendered.css(".hors-plan")).to be_empty
  end
end
