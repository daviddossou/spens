# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::StatCardComponent, type: :component do
  let(:label) { "Total Balance" }
  let(:value) { 5000.0 }
  let(:currency) { "XOF" }
  let(:trend) { nil }

  subject(:component) do
    described_class.new(
      label: label,
      value: value,
      currency: currency,
      trend: trend
    )
  end

  describe "#initialize" do
    it "sets label" do
      expect(component.label).to eq("Total Balance")
    end

    it "sets value" do
      expect(component.value).to eq(5000.0)
    end

    it "sets currency" do
      expect(component.currency).to eq("XOF")
    end

    it "defaults trend to nil" do
      expect(component.trend).to be_nil
    end

    context "with trend" do
      let(:trend) { :positive }

      it "sets trend" do
        expect(component.trend).to eq(:positive)
      end
    end

    context "without currency" do
      subject(:component) { described_class.new(label: label, value: value) }

      it "defaults currency to nil" do
        expect(component.currency).to be_nil
      end
    end
  end

  describe "rendering" do
    let(:rendered) { render_inline(component) }

    it "renders a stat-card container" do
      expect(rendered.css(".stat-card")).to be_present
    end

    it "renders the label" do
      expect(rendered.css(".stat-card__label").text).to include("Total Balance")
    end

    it "renders the abbreviated value" do
      expect(rendered.css(".stat-card__value").text).to include("5K")
    end

    it "renders the currency symbol" do
      expect(rendered.css(".stat-card__value").text).to include("FCFA")
    end

    context "with no trend" do
      let(:trend) { nil }

      it "does not add trend modifier class" do
        value_el = rendered.css(".stat-card__value").first
        expect(value_el["class"]).not_to include("stat-card__value--positive")
        expect(value_el["class"]).not_to include("stat-card__value--negative")
      end
    end

    context "with positive trend" do
      let(:trend) { :positive }

      it "adds positive modifier class" do
        value_el = rendered.css(".stat-card__value").first
        expect(value_el["class"]).to include("stat-card__value--positive")
      end

      it "does not add negative modifier class" do
        value_el = rendered.css(".stat-card__value").first
        expect(value_el["class"]).not_to include("stat-card__value--negative")
      end
    end

    context "with negative trend" do
      let(:trend) { :negative }

      it "adds negative modifier class" do
        value_el = rendered.css(".stat-card__value").first
        expect(value_el["class"]).to include("stat-card__value--negative")
      end

      it "does not add positive modifier class" do
        value_el = rendered.css(".stat-card__value").first
        expect(value_el["class"]).not_to include("stat-card__value--positive")
      end
    end

    context "with zero value" do
      let(:value) { 0 }

      it "renders formatted zero" do
        expect(rendered.css(".stat-card__value").text).to include("0")
      end
    end

    context "with large value" do
      let(:value) { 1_500_000.0 }

      it "renders abbreviated value" do
        expect(rendered.css(".stat-card__value").text).to include("1.5M")
      end
    end

    context "with value below threshold" do
      let(:value) { 500.0 }

      it "renders full value" do
        expect(rendered.css(".stat-card__value").text).to include("500")
      end
    end
  end
end
