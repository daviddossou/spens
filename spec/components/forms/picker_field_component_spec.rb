# frozen_string_literal: true

require "rails_helper"

RSpec.describe Forms::PickerFieldComponent, type: :component do
  Record = Struct.new(:account_name) unless const_defined?(:Record)

  def builder(object)
    ActionView::Helpers::FormBuilder.new("transaction", object, vc_test_controller.view_context, {})
  end

  let(:rows) do
    [
      { value: "Bank", label: "Bank", icon: "🏦", meta: "120 k" },
      { value: "Cash", label: "Cash", icon: "💵", meta: "5 k" }
    ]
  end

  def render_picker(value, **options)
    render_inline(described_class.new(
      form: builder(Record.new(value)), field: :account_name, rows: rows,
      label: "Account", placeholder: "Which account?", **options
    ))
  end

  it "mounts the picker controller with the rows and the labels" do
    root = render_picker("Bank").at_css(".form-field")
    expect(root["data-controller"]).to eq("picker")
    expect(root["data-picker-title-value"]).to eq("Account")
    expect(JSON.parse(root["data-picker-rows-value"]).map { |r| r["value"] }).to eq(%w[Bank Cash])
    expect(root["data-picker-placeholder-value"]).to eq("Which account?")
    expect(root["data-picker-allow-create-value"]).to eq("false")
    expect(root["data-picker-grouped-value"]).to eq("false")
    expect(root["data-picker-change-label-value"]).to eq(I18n.t("picker.change"))
    expect(root["data-picker-empty-label-value"]).to be_nil
    expect(root["data-picker-chain-to-value"]).to be_nil
  end

  it "submits the stored value through a hidden input and opens with a button" do
    rendered = render_picker("Bank")
    hidden = rendered.at_css("input[type=hidden]")
    expect(hidden["name"]).to eq("transaction[account_name]")
    expect(hidden["value"]).to eq("Bank")
    expect(hidden["data-picker-target"]).to eq("input")
    button = rendered.at_css("button.picker__control")
    expect(button["type"]).to eq("button")
    expect(button["data-action"]).to eq("picker#open")
    expect(button.at_css("svg.picker__chevron")).to be_present
  end

  it "shows the row label of the selected value" do
    label = render_picker("Cash").at_css(".picker__value")
    expect(label.text).to eq("Cash")
    expect(label["data-picker-target"]).to eq("label")
    expect(label["class"]).to eq("picker__value")
  end

  it "shows the placeholder as empty when nothing is chosen" do
    label = render_picker(nil).at_css(".picker__value")
    expect(label.text).to eq("Which account?")
    expect(label["class"]).to eq("picker__value picker__value--empty")
  end

  it "keeps a stored value that is no longer in the list" do
    expect(render_picker("Old savings").at_css(".picker__value").text).to eq("Old savings")
  end

  it "renders the label, the help text and the optional id" do
    rendered = render_picker(nil, help_text: "Where the money sits", id: "transfer-from")
    expect(rendered.at_css(".form-field")["id"]).to eq("transfer-from")
    expect(rendered.at_css("label.form-label")["for"]).to eq("transaction_account_name")
    expect(rendered.at_css(".form-help-text").text).to eq("Where the money sits")
  end

  it "omits the help text when blank" do
    expect(render_picker(nil).css(".form-help-text")).to be_empty
  end

  it "passes create, grouping, chaining and the empty label to the controller" do
    root = render_picker(nil,
      title: "From which account?", allow_create: true, grouped: true, empty_label: "Any account",
      chain_to: "#transfer-to", chain_reason: "Same account", chain_label: "From"
    ).at_css(".form-field")
    expect(root["data-picker-title-value"]).to eq("From which account?")
    expect(root["data-picker-allow-create-value"]).to eq("true")
    expect(root["data-picker-grouped-value"]).to eq("true")
    expect(root["data-picker-empty-label-value"]).to eq("Any account")
    expect(root["data-picker-chain-to-value"]).to eq("#transfer-to")
    expect(root["data-picker-chain-reason-value"]).to eq("Same account")
    expect(root["data-picker-chain-label-value"]).to eq("From")
  end

  it "merges extra field data onto the hidden input" do
    hidden = render_picker(nil, field_data: { goal_form_target: "accountName", action: "change->goal-form#sync" }).at_css("input[type=hidden]")
    expect(hidden["data-picker-target"]).to eq("input")
    expect(hidden["data-goal-form-target"]).to eq("accountName")
    expect(hidden["data-action"]).to eq("change->goal-form#sync")
  end
end
