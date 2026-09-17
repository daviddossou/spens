# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::ProgressBarComponent, type: :component do
  it "renders an accessible progressbar with its fill width" do
    rendered = render_inline(described_class.new(percentage: 42))
    bar = rendered.at_css(".progress-bar")
    expect(bar["role"]).to eq("progressbar")
    expect(bar["aria-valuenow"]).to eq("42")
    expect(bar["aria-valuemin"]).to eq("0")
    expect(bar["aria-valuemax"]).to eq("100")
    expect(bar["aria-label"]).to be_nil
    expect(bar.at_css(".progress-fill")["style"]).to eq("width: 42%;")
  end

  it "clamps the value and the width between 0 and 100" do
    over = render_inline(described_class.new(percentage: 130)).at_css("[role=progressbar]")
    expect(over["aria-valuenow"]).to eq("100")
    expect(over.at_css("div")["style"]).to eq("width: 100%;")

    under = render_inline(described_class.new(percentage: -5)).at_css("[role=progressbar]")
    expect(under["aria-valuenow"]).to eq("0")
    expect(under.at_css("div")["style"]).to eq("width: 0%;")
  end

  it "lets the drawn width differ from the announced value" do
    rendered = render_inline(described_class.new(percentage: 120, width: 100))
    bar = rendered.at_css("[role=progressbar]")
    expect(bar["aria-valuenow"]).to eq("100")
    expect(bar.at_css("div")["style"]).to eq("width: 100%;")
  end

  it "applies custom classes, label and value text" do
    rendered = render_inline(described_class.new(
      percentage: 75, classes: "goal-card__bar", fill_class: "goal-card__bar-fill goal-card__bar-fill--settled",
      label: "Rent: 75%", value_text: "75% spent"
    ))
    bar = rendered.at_css(".goal-card__bar")
    expect(bar["aria-label"]).to eq("Rent: 75%")
    expect(bar["aria-valuetext"]).to eq("75% spent")
    expect(bar.at_css(".goal-card__bar-fill--settled")).to be_present
  end
end
