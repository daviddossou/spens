# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::CommitmentCardComponent, type: :component do
  let(:title) { "Emergency Fund" }
  let(:current_value) { 5000.0 }
  let(:target_value) { 10000.0 }
  let(:currency) { "XOF" }
  let(:url) { nil }
  let(:complete_label) { "Complete" }
  let(:remaining_label) { "left" }

  subject(:component) do
    described_class.new(
      title: title,
      current_value: current_value,
      target_value: target_value,
      currency: currency,
      url: url,
      complete_label: complete_label,
      remaining_label: remaining_label
    )
  end

  describe "#percentage" do
    it "calculates the correct percentage" do
      expect(component.percentage).to eq(50)
    end

    it "rounds to the nearest integer" do
      expect(build(current_value: 3333.33).percentage).to eq(33)
    end

    it "caps at 100% when current exceeds target" do
      expect(build(current_value: 15_000.0).percentage).to eq(100)
    end

    it "floors at 0% for negative progress" do
      expect(build(current_value: -1000.0).percentage).to eq(0)
    end

    it "returns 0 when target is zero (no division by zero)" do
      expect(build(target_value: 0).percentage).to eq(0)
    end
  end

  describe "#remaining_value" do
    it "is the gap between target and current" do
      expect(component.remaining_value).to eq(5000.0)
    end

    it "never goes below zero when over-funded" do
      expect(build(current_value: 15_000.0).remaining_value).to eq(0)
    end
  end

  describe "#settled?" do
    it "is true once current reaches target" do
      expect(build(current_value: 10_000.0).settled?).to be(true)
    end

    it "is false while progress remains" do
      expect(component.settled?).to be(false)
    end

    it "is false when target is zero" do
      expect(build(current_value: 0, target_value: 0).settled?).to be(false)
    end

    # Regression: float drift left debts a sub-cent short of their target,
    # rendering "0.0 left" instead of the settled badge.
    it "is true when the remaining rounds to zero at currency precision" do
      expect(build(current_value: 99.996, target_value: 100.0).settled?).to be(true)
    end

    it "is false when a real cent still remains" do
      expect(build(current_value: 99.99, target_value: 100.0).settled?).to be(false)
    end
  end

  describe "formatting" do
    before { render_inline(component) }

    it "formats the current value with abbreviation and currency" do
      expect(component.formatted_current_value.to_s).to include("5K").and include("FCFA")
    end

    it "formats the target value with abbreviation and currency" do
      expect(component.formatted_target_value.to_s).to include("10K").and include("FCFA")
    end
  end

  describe "rendering" do
    context "as a summary block (no url)" do
      let(:rendered) { render_inline(component) }

      it "renders the title and a progress bar" do
        expect(rendered.css(".commitment-card--summary")).to be_present
        expect(rendered.css('[role="progressbar"]')).to be_present
      end

      it "is not wrapped in a link" do
        expect(rendered.css("a")).to be_empty
      end

      it "shows the remaining hero while in progress" do
        expect(rendered.to_html).to include(remaining_label)
        expect(rendered.css(".commitment-card__badge")).to be_empty
      end
    end

    context "as a clickable row (with url)" do
      let(:url) { "/debts/123" }
      let(:rendered) { render_inline(component) }

      it "is wrapped in a link to the url" do
        expect(rendered.css('a[href="/debts/123"]')).to be_present
        expect(rendered.css(".commitment-card--row")).to be_present
      end

      it "shows the remaining amount while in progress" do
        expect(rendered.css(".commitment-card__remaining")).to be_present
        expect(rendered.css(".commitment-card__badge")).to be_empty
      end

      context "when settled" do
        let(:current_value) { 10_000.0 }

        it "shows the completion badge instead of a remaining amount" do
          expect(rendered.to_html).to include(complete_label)
          expect(rendered.css(".commitment-card__remaining")).to be_empty
        end
      end
    end

    context "with a chosen accent" do
      let(:rendered) do
        render_inline(
          described_class.new(
            title: title, current_value: current_value, target_value: target_value,
            currency: currency, accent: "warning"
          )
        )
      end

      it "applies the accent modifier class" do
        expect(rendered.css(".commitment-card--accent-warning")).to be_present
      end
    end
  end

  describe "edge cases" do
    it "coerces string values to floats" do
      expect(build(current_value: "5000", target_value: "10000").percentage).to eq(50)
    end

    it "abbreviates very large values" do
      component = build(current_value: 1_000_000_000.0, target_value: 2_000_000_000.0)
      render_inline(component)
      expect(component.percentage).to eq(50)
      expect(component.formatted_current_value.to_s).to include("1B").and include("FCFA")
    end
  end

  def build(**overrides)
    described_class.new(
      **{
        title: title, current_value: current_value, target_value: target_value,
        currency: currency, url: url, complete_label: complete_label,
        remaining_label: remaining_label
      }.merge(overrides)
    )
  end
end
