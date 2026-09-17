# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analytics::SpendingSummaryComponent, type: :component do
  before { stub_current_space(build_stubbed(:space, currency: "XOF")) }

  let(:today) { Date.new(2026, 9, 17) }
  let(:period) { Analyses::Period.new("month", today: today) }
  let(:range) { period.range }
  let(:spent_total) { 120_000.0 }
  let(:prorated_plan_total) { 85_000.0 }
  let(:overruns) { [] }
  let(:lent_total) { 0.0 }
  let(:spending_plan) { plan }
  let(:spending) do
    double(spent_total: spent_total, prorated_plan_total: prorated_plan_total, plan: spending_plan,
           overruns: overruns, lent_total: lent_total)
  end
  let(:comparison) { nil }
  let(:plan) { nil }
  let(:split) { nil }
  let(:rendered) do
    render_inline(described_class.new(period: period, spending: spending, range: range,
                                      comparison: comparison, plan: plan, split: split))
  end

  describe "the hero" do
    it "names the month and the total" do
      expect(rendered.at_css(".analyses-card__label").text.squish).to eq("You spent in September")
      expect(rendered.at_css(".analyses-hero").text).to include("120,000")
    end

    context "over a custom range" do
      let(:period) { Analyses::Period.new("custom", start_date: "2026-09-01", end_date: "2026-09-10", today: today) }

      it "names both bounds" do
        expect(rendered.at_css(".analyses-card__label").text.squish).to eq("You spent from 1 September to 10 September")
      end
    end
  end

  describe "the comparison" do
    it "says nothing without one" do
      expect(rendered.at_css(".analyses-compare")).to be_nil
    end

    context "with too little data" do
      let(:comparison) { { no_data: true } }

      it "says nothing" do
        expect(rendered.at_css(".analyses-compare")).to be_nil
      end
    end

    context "as a monthly average" do
      let(:comparison) { { monthly_average: 10_000 } }

      it "reads quietly" do
        line = rendered.at_css(".analyses-compare--quiet")
        expect(line.text.squish).to match(/\AOn average 10,000.FCFA a month\z/)
      end
    end

    context "up against the same point last month" do
      let(:comparison) { { percent: 12, previous: 100_000.0, range: Date.new(2026, 8, 1)..Date.new(2026, 8, 17) } }

      it "shows an up chip and names the month" do
        chip = rendered.at_css(".analyses-compare__chip")
        expect(chip["class"]).to include("analyses-compare__chip--up")
        expect(chip.text).to eq("↑ 12 %")
        expect(rendered.at_css(".analyses-compare__ref").text.squish).to match(/vs the same point in August \(100,000.FCFA\)/)
      end
    end

    context "down" do
      let(:comparison) { { percent: -8, previous: 130_000.0, range: Date.new(2026, 8, 1)..Date.new(2026, 8, 17) } }

      it "shows a down chip" do
        chip = rendered.at_css(".analyses-compare__chip")
        expect(chip["class"]).to include("analyses-compare__chip--down")
        expect(chip.text).to eq("↓ 8 %")
      end
    end

    context "against a small base" do
      let(:comparison) { { amount: 5_000, previous: 2_000.0, range: Date.new(2026, 8, 1)..Date.new(2026, 8, 17) } }

      it "shows the gap in money, signed" do
        expect(rendered.at_css(".analyses-compare__chip").text.squish).to match(/\A\+.5,000.FCFA\z/)
      end
    end

    context "over a custom range" do
      let(:period) { Analyses::Period.new("custom", start_date: "2026-09-01", end_date: "2026-09-10", today: today) }
      let(:comparison) { { percent: 3, previous: 90_000.0, range: Date.new(2026, 8, 22)..Date.new(2026, 8, 31) } }

      it "refers to the period before" do
        expect(rendered.at_css(".analyses-compare__ref").text.squish).to match(/\Avs the period before \(90,000.FCFA\)\z/)
      end
    end
  end

  describe "the plan" do
    it "shows no plan row without one" do
      expect(rendered.at_css(".analyses-row")).to be_nil
    end

    context "mid-month" do
      let(:plan) { { planned: 150_000.0, spent_on_plan: 100_000.0 } }

      it "reads spent against planned with the prorated tick" do
        expect(rendered.at_css(".analyses-row__label").text).to eq("Against what you planned")
        expect(rendered.at_css(".analyses-row__value").text.squish).to match(/100,000.FCFA \/ 150,000.FCFA/)
        expect(rendered.at_css(".analyses-row__value")["class"]).not_to include("--over")
        expect(rendered.at_css(".analyses-bar")["class"]).not_to include("analyses-bar--over")
        expect(rendered.at_css(".analyses-bar__fill")["style"]).to include("width: 66.7%")
        expect(rendered.at_css(".analyses-bar__tick")["style"]).to include("left: 56.7%")
      end

      it "gives the verdict in money above pace" do
        expect(rendered.at_css(".analyses-row__caption--verdict").text.squish).to match(/\AYou're 15,000.FCFA above your planned pace\.\z/)
      end

      context "under pace" do
        let(:plan) { { planned: 150_000.0, spent_on_plan: 70_000.0 } }

        it "says so" do
          expect(rendered.at_css(".analyses-row__caption--verdict").text.squish).to match(/\AYou're 15,000.FCFA under your planned pace\.\z/)
        end
      end

      context "exactly on pace" do
        let(:plan) { { planned: 150_000.0, spent_on_plan: 85_000.0 } }

        it "says so" do
          expect(rendered.at_css(".analyses-row__caption--verdict").text.squish).to eq("You're exactly on pace.")
        end
      end

      context "past the full plan" do
        let(:plan) { { planned: 150_000.0, spent_on_plan: 160_000.0 } }

        it "turns the row over and caps the fill" do
          expect(rendered.at_css(".analyses-row__value")["class"]).to include("analyses-row__value--over")
          expect(rendered.at_css(".analyses-bar")["class"]).to include("analyses-bar--over")
          expect(rendered.at_css(".analyses-bar__fill")["style"]).to include("width: 100")
        end
      end
    end

    context "once the period is over" do
      let(:prorated_plan_total) { 150_000.0 }
      let(:plan) { { planned: 150_000.0, spent_on_plan: 100_000.0 } }

      it "drops the tick and closes the verdict" do
        expect(rendered.at_css(".analyses-bar__tick")).to be_nil
        expect(rendered.at_css(".analyses-row__caption--verdict").text.squish).to match(/\AYou kept your plan, 50,000.FCFA to spare\.\z/)
      end

      context "exceeded" do
        let(:plan) { { planned: 150_000.0, spent_on_plan: 170_000.0 } }

        it "states the overrun" do
          expect(rendered.at_css(".analyses-row__caption--verdict").text.squish).to match(/\APlan exceeded by 20,000.FCFA\.\z/)
        end
      end

      context "to the franc" do
        let(:plan) { { planned: 150_000.0, spent_on_plan: 150_000.0 } }

        it "says so" do
          expect(rendered.at_css(".analyses-row__caption--verdict").text.squish).to eq("You kept your plan to the franc.")
        end
      end
    end

    context "over twelve months" do
      let(:period) { Analyses::Period.new("twelve_months", today: today) }
      let(:plan) { { months_ok: 9, months_total: 12 } }

      it "counts the months inside their plan" do
        caption = rendered.at_css(".analyses-row__caption")
        expect(caption.at_css("strong").text).to eq("9 months out of 12")
        expect(caption.text.squish).to end_with("inside your plan")
      end
    end
  end

  describe "the essential split" do
    let(:split) { { essential: 60_000.0, plaisir: 40_000.0, unclassified: 20_000.0, pct_essential: 50 } }

    it "reads the share, the bar and the three amounts" do
      expect(rendered.at_css(".analyses-row__label").text).to eq("Essential / treat")
      expect(rendered.at_css(".analyses-row__value").text).to eq("50% essential")
      expect(rendered.at_css(".analyses-splitbar__essential")["style"]).to include("width: 50.0%")
      caption = rendered.at_css(".analyses-splitbar + .analyses-row__caption")
      expect(caption.css("strong").map(&:text)).to all(include("FCFA"))
      expect(caption.text.squish).to include("essential")
      expect(caption.text.squish).to include("treat")
      expect(caption.text.squish).to include("unclassified")
    end

    context "with everything classified" do
      let(:split) { { essential: 60_000.0, plaisir: 60_000.0, unclassified: 0.0, pct_essential: 50 } }

      it "drops the unclassified amount" do
        expect(rendered.at_css(".analyses-splitbar + .analyses-row__caption").text).not_to include("unclassified")
      end
    end
  end

  describe "the all-good line" do
    let(:spending_plan) { { planned: 1.0 } }

    it "shows when a single month has a plan and no overrun" do
      expect(rendered.at_css(".analyses-allgood").text).to eq("Everything is inside your plan")
    end

    context "with an overrun" do
      let(:overruns) { [ :one ] }

      it "stays out" do
        expect(rendered.at_css(".analyses-allgood")).to be_nil
      end
    end

    context "over several months" do
      let(:period) { Analyses::Period.new("three_months", today: today) }

      it "stays out" do
        expect(rendered.at_css(".analyses-allgood")).to be_nil
      end
    end
  end

  describe "money lent" do
    it "says nothing when none left" do
      expect(rendered.at_css(".analyses-moved")).to be_nil
    end

    context "when loans went out" do
      let(:lent_total) { 25_000.0 }

      it "adds a line pointing to the debts section" do
        link = rendered.at_css("a.analyses-moved")
        expect(link["href"]).to eq("#analyses-between")
        expect(link.text.squish).to match(/You also lent 25,000.FCFA over the period/)
      end
    end
  end
end
