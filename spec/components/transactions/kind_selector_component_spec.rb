# frozen_string_literal: true

require "rails_helper"

RSpec.describe Transactions::KindSelectorComponent, type: :component do
  let(:options) do
    [
      { value: "expense", label: "Expense", url: "/transactions/new?kind=expense", selected: true, filled: true },
      { value: "income", label: "Income", url: "/transactions/new?kind=income", selected: false },
      { value: "transfer", label: "Transfer", url: "/transactions/new?kind=transfer", selected: false },
      { value: "debt", label: "Debt", url: "/transactions/new?kind=debt_out", selected: false }
    ]
  end
  let(:data) { { turbo_frame: "transaction_form", action: "kind-switch#switch" } }

  let(:rendered) { render_inline(described_class.new(options: options, label: "Type", data: data)) }

  it "is a labelled radiogroup" do
    group = rendered.at_css(".kind-selector")
    expect(group["role"]).to eq("radiogroup")
    expect(group["aria-label"]).to eq("Type")
  end

  it "renders each option as a radio link with its icon and label" do
    radios = rendered.css("a[role='radio']")
    expect(radios.size).to eq(4)
    expect(radios.map { |r| r["href"] }).to eq(options.map { |o| o[:url] })
    expect(radios.map { |r| r.at_css(".kind-option__label").text }).to eq(%w[Expense Income Transfer Debt])
    expect(radios.first.at_css(".kind-option__icon--expense svg")).to be_present
    expect(radios.first.at_css(".kind-option__icon")["aria-hidden"]).to eq("true")
  end

  it "marks the selected option checked, selected and filled" do
    selected = rendered.at_css("a.kind-option--expense")
    expect(selected["aria-checked"]).to eq("true")
    expect(selected["class"]).to include("kind-option--selected", "kind-option--filled")
    other = rendered.at_css("a.kind-option--income")
    expect(other["aria-checked"]).to eq("false")
    expect(other["class"]).not_to include("kind-option--selected")
    expect(other["class"]).not_to include("kind-option--filled")
  end

  it "carries the data attributes on every option" do
    rendered.css("a[role='radio']").each do |radio|
      expect(radio["data-turbo-frame"]).to eq("transaction_form")
      expect(radio["data-action"]).to eq("kind-switch#switch")
    end
  end

  context "without data" do
    let(:rendered) { render_inline(described_class.new(options: options, label: "Type")) }

    it "renders plain links" do
      expect(rendered.at_css("a[role='radio']")["data-action"]).to be_nil
    end
  end
end
