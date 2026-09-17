# frozen_string_literal: true

require "rails_helper"

RSpec.describe Marketing::GuideStepComponent, type: :component do
  let(:number) { nil }
  let(:rendered) do
    render_inline(described_class.new(title: "How much do you have?", description: "Gather everything in one place.",
                                      phase: "See", number: number))
  end
  let(:step) { rendered.at_css(".guide-step") }

  it "shows the phase, title and description" do
    expect(step.at_css(".guide-step__phase").text).to eq("See")
    expect(step.at_css(".guide-step__title").text).to eq("How much do you have?")
    expect(step.at_css(".guide-step__desc").text).to eq("Gather everything in one place.")
  end

  it "has no numbered head without a number" do
    expect(step.at_css(".guide-step__head")).to be_nil
    expect(step.at_css(".guide-step__num")).to be_nil
  end

  context "with a number" do
    let(:number) { "02" }

    it "pairs the number with the phase in a head" do
      head = step.at_css(".guide-step__head")
      expect(head.at_css(".guide-step__num").text).to eq("02")
      expect(head.at_css(".guide-step__phase").text).to eq("See")
      expect(step.css(".guide-step__phase").size).to eq(1)
    end
  end
end
