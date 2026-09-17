# frozen_string_literal: true

require "rails_helper"

RSpec.describe Debts::DirectionFieldComponent, type: :component do
  let(:rendered) { render_inline(described_class.new(direction: "borrowed")) }

  it "is a labelled radio group submitting debt[direction]" do
    expect(rendered.at_css('[role="radiogroup"]')["aria-label"]).to eq("Loan or debt?")
    radios = rendered.css('input[type="radio"]')
    expect(radios.map { |r| r["name"] }.uniq).to eq([ "debt[direction]" ])
    expect(radios.map { |r| r["value"] }).to eq(%w[lent borrowed])
    expect(radios.map { |r| r["data-action"] }.uniq).to eq([ "change->debt-form#onDirection" ])
  end

  it "checks the given direction only" do
    expect(rendered.at_css('input[value="borrowed"]')["checked"]).to be_present
    expect(rendered.at_css('input[value="lent"]')["checked"]).to be_nil
  end

  it "labels each card and ties it to its input" do
    rendered.css('input[type="radio"]').each do |radio|
      expect(rendered.at_css("label[for=\"#{radio['id']}\"]")["class"]).to include("debt-direction__card--#{radio['value']}")
    end
    expect(rendered.css(".debt-direction__title").map(&:text)).to eq([ "I lent", "I borrowed" ])
    expect(rendered.css(".debt-direction__sub").map(&:text)).to eq([ "I'll be owed", "I'll owe" ])
    expect(rendered.text).not_to include("translation missing")
  end
end
