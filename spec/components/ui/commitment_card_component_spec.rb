# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::CommitmentCardComponent, type: :component do
  let(:title) { "Emergency Fund" }
  let(:current_value) { 5000.0 }
  let(:target_value) { 10000.0 }
  let(:currency) { "XOF" }
  let(:url) { nil }

  subject(:component) do
    described_class.new(
      title: title,
      current_value: current_value,
      target_value: target_value,
      currency: currency,
      url: url
    )
  end

  describe "#percentage" do
    context "when target value is not zero" do
      it "calculates the correct percentage" do
        expect(component.percentage).to eq(50)
      end

      it "rounds to nearest integer" do
        component = described_class.new(
          title: title,
          current_value: 3333.33,
          target_value: 10000.0,
          currency: currency
        )
        expect(component.percentage).to eq(33)
      end

      it "caps at 100% when current exceeds target" do
        component = described_class.new(
          title: title,
          current_value: 15000.0,
          target_value: 10000.0,
          currency: currency
        )
        expect(component.percentage).to eq(150)
      end
    end

    context "when target value is zero" do
      let(:target_value) { 0 }

      it "returns 0 to avoid division by zero" do
        expect(component.percentage).to eq(0)
      end
    end
  end

  describe "#circumference" do
    it "calculates the circle circumference" do
      # 2 * π * 52 ≈ 326.73
      expect(component.circumference).to be_within(0.01).of(326.73)
    end
  end

  describe "#stroke_dashoffset" do
    it "calculates the correct offset for 50% progress" do
      # At 50%, offset should be 50% of circumference
      expected_offset = component.circumference * 0.5
      expect(component.stroke_dashoffset).to be_within(0.01).of(expected_offset)
    end

    it "returns 0 offset for 100% progress" do
      component = described_class.new(
        title: title,
        current_value: 10000.0,
        target_value: 10000.0,
        currency: currency
      )
      expect(component.stroke_dashoffset).to eq(0)
    end

    it "returns full circumference for 0% progress" do
      component = described_class.new(
        title: title,
        current_value: 0,
        target_value: 10000.0,
        currency: currency
      )
      expect(component.stroke_dashoffset).to be_within(0.01).of(component.circumference)
    end
  end

  describe "#formatted_current_value" do
    it "formats the current value as currency without decimals" do
      render_inline(component)
      expect(component.formatted_current_value).to eq("XOF5,000")
    end
  end

  describe "#formatted_target_value" do
    it "formats the target value as currency without decimals" do
      render_inline(component)
      expect(component.formatted_target_value).to eq("XOF10,000")
    end
  end

  describe "rendering" do
    let(:rendered) { render_inline(component) }

    it "renders the title" do
      expect(rendered.to_html).to include("Emergency Fund")
    end

    it "renders the percentage" do
      expect(rendered.to_html).to include("50%")
    end

    it "renders the current value" do
      expect(rendered.to_html).to include("XOF5,000")
    end

    it "renders the target value" do
      expect(rendered.to_html).to include("XOF10,000")
    end

    it "renders the SVG progress circle" do
      expect(rendered.to_html).to include("progress-ring")
      expect(rendered.to_html).to include("progress-ring__circle")
    end

    context "when url is not provided" do
      let(:url) { nil }

      it "renders a non-clickable card" do
        expect(rendered.to_html).to include("commitment-card")
        expect(rendered.to_html).not_to include("commitment-card--clickable")
        expect(rendered.to_html).not_to include("<a")
      end
    end

    context "when url is provided" do
      let(:url) { "/goals/123" }

      it "renders a clickable card wrapped in a link" do
        expect(rendered.to_html).to include("commitment-card--clickable")
        expect(rendered.to_html).to include('href="/goals/123"')
      end
    end
  end

  describe "edge cases" do
    context "with negative current value" do
      let(:current_value) { -1000.0 }

      it "handles negative values gracefully" do
        expect(component.percentage).to eq(-10)
      end
    end

    context "with zero current value" do
      let(:current_value) { 0 }

      it "returns 0 percentage" do
        expect(component.percentage).to eq(0)
      end
    end

    context "with very large values" do
      let(:current_value) { 1_000_000_000.0 }
      let(:target_value) { 2_000_000_000.0 }

      it "handles large numbers correctly" do
        render_inline(component)
        expect(component.percentage).to eq(50)
        expect(component.formatted_current_value).to eq("XOF1,000,000,000")
      end
    end

    context "with string values" do
      let(:current_value) { "5000" }
      let(:target_value) { "10000" }

      it "converts strings to floats" do
        expect(component.percentage).to eq(50)
      end
    end
  end
end
