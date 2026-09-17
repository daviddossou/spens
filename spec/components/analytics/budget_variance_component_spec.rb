# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analytics::BudgetVarianceComponent, type: :component do
  before { stub_current_space(build_stubbed(:space, currency: "XOF")) }

  def plan_row(name, spent:, planned:, prorated:, single: false)
    gap = (spent - prorated).round(2)
    Analyses::SpendingQuery::PlanRow.new(
      entry: double(id: "entry-#{name.parameterize}"), name: name, spent: spent, planned: planned,
      prorated: prorated, gap: gap, single: single, rel_gap: planned.positive? ? gap / planned : 0
    )
  end

  def offplan_row(name, spent, other: false)
    Analyses::SpendingQuery::OffplanRow.new(name: name, spent: spent, other: other)
  end

  let(:period) { Analyses::Period.new("month", today: Date.new(2026, 9, 17)) }
  let(:plan) { { categories_with_plan: 4, categories_total: 6 } }
  let(:overruns) { [ plan_row("Food", spent: 60_000.0, planned: 100_000.0, prorated: 50_000.0) ] }
  let(:within) { [] }
  let(:offplan) { [] }
  let(:spent_total) { 200_000.0 }
  let(:offplan_total) { 0.0 }
  let(:spending) do
    double(plan: plan, overruns: overruns, within_plan: within, offplan_categories: offplan,
           spent_total: spent_total, offplan_total: offplan_total)
  end
  let(:rendered) { render_inline(described_class.new(period: period, spending: spending, plan: plan)) }

  context "over several months" do
    let(:period) { Analyses::Period.new("three_months", today: Date.new(2026, 9, 17)) }

    it "renders nothing" do
      expect(rendered.to_html.strip).to be_empty
    end
  end

  context "without a plan" do
    let(:plan) { nil }

    it "renders nothing" do
      expect(rendered.to_html.strip).to be_empty
    end
  end

  describe "overruns" do
    it "lists them under a count against the planned categories" do
      card = rendered.at_css(".analyses-card")
      expect(card.at_css(".analyses-card__title").text).to include("Ahead of pace")
      expect(card.at_css(".analyses-card__count").text).to eq("1 of 4")
      expect(card.css("a.analyses-overrun").map { |a| a["href"] }).to eq([ "/budget_entries/entry-food/edit" ])
      expect(card.at_css("details")).to be_nil
    end

    context "with more than three" do
      let(:overruns) do
        %w[Food Taxi Phone Rent Gifts].map { |name| plan_row(name, spent: 60_000.0, planned: 100_000.0, prorated: 50_000.0) }
      end

      it "shows three and folds the rest" do
        card = rendered.at_css(".analyses-card")
        expect(card.at_css(".analyses-card__count").text).to eq("3 of 4")
        expect(card.css("> a.analyses-overrun").size).to eq(3)
        fold = card.at_css("details.analyses-fold")
        expect(fold.at_css("summary").text).to include("2 more, smaller")
        expect(fold.at_css(".analyses-fold__toggle").text).to eq("See")
        expect(fold.css("a.analyses-overrun").size).to eq(2)
      end
    end

    context "when there are none" do
      let(:overruns) { [] }

      it "shows no overrun card" do
        expect(rendered.css(".analyses-card__count")).to be_empty
      end
    end
  end

  describe "lines within their plan" do
    let(:within) do
      [ plan_row("Rent", spent: 80_000.0, planned: 80_000.0, prorated: 80_000.0, single: true),
        plan_row("Fuel", spent: 10_000.0, planned: 40_000.0, prorated: 20_000.0) ]
    end

    it "folds them with their totals" do
      fold = rendered.css("details.analyses-fold").find { |d| d.at_css(".analyses-fold__title") }
      expect(fold.at_css(".analyses-fold__title").text).to eq("2 categories inside their plan")
      expect(fold.at_css(".analyses-fold__sub").text).to match(/90,000.FCFA spent · 120,000.FCFA planned/)
    end

    it "links each line to its budget entry in the modal frame" do
      links = rendered.css("a.analyses-slim")
      expect(links.map { |a| a["href"] }).to eq([ "/budget_entries/entry-rent/edit", "/budget_entries/entry-fuel/edit" ])
      expect(links.map { |a| a["data-turbo-frame"] }.uniq).to eq([ "modal" ])
    end

    it "marks a paid single-transaction line and draws no tick for it" do
      rent = rendered.css("a.analyses-slim").first
      expect(rent.at_css(".analyses-slim__chip").text).to eq("paid")
      expect(rent.at_css(".analyses-slim__bar > span")["style"]).to include("width: 100.0%")
      expect(rent.at_css(".analyses-slim__tick")).to be_nil
    end

    it "ticks the prorated plan on a running line" do
      fuel = rendered.css("a.analyses-slim").last
      expect(fuel.at_css(".analyses-slim__chip")).to be_nil
      expect(fuel.at_css(".analyses-slim__bar > span")["style"]).to include("width: 25.0%")
      expect(fuel.at_css(".analyses-slim__tick")["style"]).to include("left: 50.0%")
    end

    context "with a single line" do
      let(:within) { [ plan_row("Fuel", spent: 10_000.0, planned: 40_000.0, prorated: 20_000.0) ] }

      it "uses the singular title" do
        expect(rendered.at_css(".analyses-fold__title").text).to eq("1 category inside its plan")
      end
    end
  end

  describe "off-plan spend" do
    let(:offplan) { [ offplan_row("Taxi", 30_000.0), offplan_row("Other", 20_000.0, other: true) ] }
    let(:offplan_total) { 50_000.0 }
    let(:fold) { rendered.css("details.analyses-fold").find { |d| d.text.include?("off-plan") } }

    it "folds it with its total and the plan coverage" do
      expect(fold.at_css(".analyses-fold__title").text).to eq("2 off-plan categories")
      sub = fold.at_css(".analyses-fold__sub").text.squish
      expect(sub).to include("50,000")
      expect(sub).to include("no budget")
      expect(sub).to include("4 of your 6 categories have a plan")
    end

    it "offers to budget a real category, prefilled, in the modal" do
      link = fold.css("a.analyses-slim__action").first
      expect(link.text).to eq("Budget it")
      expect(link["data-turbo-frame"]).to eq("modal")
      uri = URI.parse(link["href"])
      expect(uri.path).to eq("/budget_items/new")
      expect(Rack::Utils.parse_query(uri.query)).to eq(
        "month" => "2026-09", "kind" => "expense", "transaction_type_name" => "Taxi", "amount" => "30000"
      )
    end

    it "offers to classify the uncategorised bucket from the dashboard" do
      link = fold.css("a.analyses-slim__action").last
      expect(link.text).to eq("Classify")
      expect(link["href"]).to eq("/dashboard?q=Other")
      expect(link["data-turbo-frame"]).to eq("_top")
    end

    context "under a tenth of the total" do
      let(:offplan_total) { 15_000.0 }

      it "stays out of the page" do
        expect(fold).to be_nil
      end
    end

    context "with more than three categories" do
      let(:offplan) { %w[A B C D E].map { |n| offplan_row(n, 10_000.0) } }

      it "shows three and sums the tail in a muted row" do
        expect(fold.css("a.analyses-slim__action").size).to eq(3)
        muted = fold.at_css(".analyses-slim--muted")
        expect(muted.at_css(".analyses-slim__name").text).to eq("+ 2 more")
        expect(muted.at_css(".analyses-slim__amount").text).to include("20,000")
      end
    end
  end
end
