# frozen_string_literal: true

require "rails_helper"

RSpec.describe Forms::ToggleFieldComponent, type: :component do
  it "submits zero when unchecked and one when checked, under the same name" do
    rendered = render_inline(described_class.new(name: "budget_item[rollover]", checked: false, label: "Carry over"))
    hidden = rendered.at_css("input[type=hidden]")
    expect(hidden["name"]).to eq("budget_item[rollover]")
    expect(hidden["value"]).to eq("0")
    expect(hidden["id"]).to be_nil
    checkbox = rendered.at_css("input[type=checkbox]")
    expect(checkbox["name"]).to eq("budget_item[rollover]")
    expect(checkbox["value"]).to eq("1")
    expect(checkbox["checked"]).to be_nil
    expect(checkbox["class"]).to eq("budget-toggle__input")
  end

  it "checks the box when checked" do
    rendered = render_inline(described_class.new(name: "budget_item[rollover]", checked: true, label: "Carry over"))
    expect(rendered.at_css("input[type=checkbox]")["checked"]).to be_present
  end

  it "wraps everything in one label with a decorative track" do
    rendered = render_inline(described_class.new(name: "x", checked: false, label: "Carry over"))
    label = rendered.at_css("label.budget-toggle")
    expect(label.at_css(".budget-toggle__label").text).to eq("Carry over")
    expect(label.at_css(".budget-toggle__track")["aria-hidden"]).to eq("true")
    expect(label.css(".budget-toggle__sub")).to be_empty
  end

  it "renders the hint slot only with hint data, and forwards data to the checkbox" do
    rendered = render_inline(described_class.new(
      name: "x", checked: false, label: "Carry over",
      hint_data: { budget_line_target: "rolloverExample" },
      data: { budget_line_target: "rollover", action: "budget-line#syncSummary" }
    ))
    expect(rendered.at_css(".budget-toggle__sub")["data-budget-line-target"]).to eq("rolloverExample")
    checkbox = rendered.at_css("input[type=checkbox]")
    expect(checkbox["data-budget-line-target"]).to eq("rollover")
    expect(checkbox["data-action"]).to eq("budget-line#syncSummary")
  end
end
