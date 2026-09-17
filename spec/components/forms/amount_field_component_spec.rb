# frozen_string_literal: true

require "rails_helper"

RSpec.describe Forms::AmountFieldComponent, type: :component do
  def builder(object = nil)
    ActionView::Helpers::FormBuilder.new("debt", object, vc_test_controller.view_context, {})
  end

  it "renders a decimal number input through the form builder with its currency" do
    rendered = render_inline(described_class.new(
      form: builder, field: :total_lent, value: 25_000, currency: "FCFA", aria_label: "Amount",
      placeholder: "0", autofocus: true, data: { debt_form_target: "amount", action: "input->debt-form#onAmount" }
    ))
    input = rendered.at_css("input.budget-amount__input")
    expect(input["type"]).to eq("number")
    expect(input["name"]).to eq("debt[total_lent]")
    expect(input["value"]).to eq("25000")
    expect(input["step"]).to eq("0.01")
    expect(input["min"]).to eq("0.01")
    expect(input["inputmode"]).to eq("decimal")
    expect(input["aria-label"]).to eq("Amount")
    expect(input["autofocus"]).to be_present
    expect(input["required"]).to be_nil
    expect(input["data-debt-form-target"]).to eq("amount")
    expect(input["data-action"]).to eq("input->debt-form#onAmount")
    expect(rendered.at_css(".budget-amount__currency").text).to eq("FCFA")
  end

  it "keeps the cents of a decimal value and leaves a blank value empty" do
    decimal = render_inline(described_class.new(form: builder, field: :amount, value: BigDecimal("12.50"), currency: "€", aria_label: "A"))
    expect(decimal.at_css("input")["value"]).to eq("12.5")

    blank = render_inline(described_class.new(form: builder, field: :amount, value: nil, currency: "€", aria_label: "A"))
    expect(blank.at_css("input")["value"]).to be_nil
  end

  it "renders a bare named input without a builder" do
    rendered = render_inline(described_class.new(
      name: :amount, value: 1500.0, currency: "FCFA", aria_label: "Amount", required: true, min: "0"
    ))
    input = rendered.at_css("input")
    expect(input["name"]).to eq("amount")
    expect(input["id"]).to eq("amount")
    expect(input["value"]).to eq("1500")
    expect(input["required"]).to be_present
    expect(input["min"]).to eq("0")
  end

  it "renders the period slot and the block content, and appends classes" do
    rendered = render_inline(described_class.new(
      form: builder, field: :amount, currency: "€", aria_label: "A", classes: "transaction-form__amount"
    )) do |amount|
      amount.with_period { '<span class="budget-amount__period">per month</span>'.html_safe }
      '<p class="extra">candidates</p>'.html_safe
    end
    expect(rendered.at_css(".budget-amount")["class"]).to eq("budget-amount transaction-form__amount")
    expect(rendered.at_css(".budget-amount__period").text).to eq("per month")
    expect(rendered.at_css(".extra").text).to eq("candidates")
  end

  it "renders no period without the slot" do
    rendered = render_inline(described_class.new(form: builder, field: :amount, currency: "€", aria_label: "A"))
    expect(rendered.css(".budget-amount__period")).to be_empty
  end
end
