# frozen_string_literal: true

require "rails_helper"

RSpec.describe Marketing::CalculatorComponent, type: :component do
  let(:rendered) { render_inline(described_class.new) }
  let(:section) { rendered.at_css("section.landing-sect") }

  it "hands the section to the calculator controller" do
    expect(section["data-controller"]).to eq("savings-calculator")
  end

  it "recomputes on every input, from a numeric income and a bounded slider" do
    income = section.at_css("#landing-calc-income")
    expect(income["data-savings-calculator-target"]).to eq("income")
    expect(income["data-action"]).to eq("input->savings-calculator#compute")
    expect(income["inputmode"]).to eq("numeric")
    expect(income["value"]).to eq("150000")

    slider = section.at_css("#landing-calc-pct")
    expect(slider["type"]).to eq("range")
    expect(slider["data-savings-calculator-target"]).to eq("slider")
    expect(slider["data-action"]).to eq("input->savings-calculator#compute")
    expect(%w[min max value].map { |a| slider[a] }).to eq(%w[1 40 10])
  end

  it "labels both inputs" do
    expect(section.at_css('label[for="landing-calc-income"]')).to be_present
    expect(section.at_css('label[for="landing-calc-pct"]')).to be_present
  end

  it "exposes every output the controller writes to" do
    targets = section.css("[data-savings-calculator-target]").map { |el| el["data-savings-calculator-target"] }
    expect(targets).to contain_exactly("income", "pct", "slider", "monthly", "y1", "y3", "y10")
    expect(section.at_css('[data-savings-calculator-target="y10"]').text).to eq("1 800 000")
  end

  it "marks every currency label so the locale picker can swap it" do
    expect(section.css("[data-currency-label]").map(&:text).uniq).to eq([ "XOF" ])
    expect(section.css("[data-currency-label]").size).to eq(5)
  end

  %i[fr en].each do |locale|
    it "reads fully in #{locale}" do
      I18n.with_locale(locale) do
        html = render_inline(described_class.new)
        expect(html.css(".translation_missing")).to be_empty
        expect(html.at_css("h2.landing-h2").text).to eq(I18n.t("landing.calculator.title"))
        expect(html.at_css(".landing-calc__note").text).to eq(I18n.t("landing.calculator.note"))
      end
    end
  end
end
