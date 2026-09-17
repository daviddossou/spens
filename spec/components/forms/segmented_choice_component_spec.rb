# frozen_string_literal: true

require "rails_helper"

RSpec.describe Forms::SegmentedChoiceComponent, type: :component do
  let(:options) do
    [
      { label: "6 months", data: { deadline_mode: "m6" } },
      { label: "1 year", selected: true, data: { deadline_mode: "y1" } },
      { label: "No deadline", data: { deadline_mode: "none" } }
    ]
  end

  let(:rendered) do
    render_inline(described_class.new(options: options, data: { goal_form_target: "deadlinePill", action: "goal-form#setDeadline" }))
  end

  it "renders one non-submitting button per option" do
    buttons = rendered.css(".pill-choice button")
    expect(buttons.size).to eq(3)
    expect(buttons.map { |b| b["type"] }.uniq).to eq([ "button" ])
    expect(buttons.map(&:text)).to eq([ "6 months", "1 year", "No deadline" ])
  end

  it "marks the selected option active" do
    expect(rendered.css("button.pill--active").map(&:text)).to eq([ "1 year" ])
    expect(rendered.css("button:not(.pill--active)").size).to eq(2)
  end

  it "merges the shared data with each option's own data" do
    button = rendered.css("button").first
    expect(button["data-goal-form-target"]).to eq("deadlinePill")
    expect(button["data-action"]).to eq("goal-form#setDeadline")
    expect(button["data-deadline-mode"]).to eq("m6")
  end

  it "honours custom container, button and active classes" do
    rendered = render_inline(described_class.new(
      options: [ { label: "Monthly", selected: true } ], classes: "seg-group", button_class: "seg", active_class: "seg--active"
    ))
    expect(rendered.at_css(".seg-group")).to be_present
    expect(rendered.at_css("button")["class"]).to eq("seg seg--active")
  end

  it "raises when an option has no label" do
    expect { render_inline(described_class.new(options: [ { data: {} } ])) }.to raise_error(KeyError)
  end
end
