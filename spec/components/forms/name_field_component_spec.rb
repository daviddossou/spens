# frozen_string_literal: true

require "rails_helper"

RSpec.describe Forms::NameFieldComponent, type: :component do
  def builder(object = nil)
    ActionView::Helpers::FormBuilder.new("transaction", object, vc_test_controller.view_context, {})
  end

  let(:rendered) do
    render_inline(described_class.new(
      form: builder, field: :contact_name, label: "With whom?", placeholder: "A first name",
      suggestions: [ "Georges", "Awa" ], see_all_title: "Everyone",
      field_data: { action: "input->debt-fields#onPersonChange" }
    ))
  end

  it "mounts the name-chips controller with the suggestions and the see-all labels" do
    root = rendered.at_css(".form-field")
    expect(root["data-controller"]).to eq("name-chips")
    expect(JSON.parse(root["data-name-chips-suggestions-value"])).to eq([ "Georges", "Awa" ])
    expect(root["data-name-chips-see-all-label-value"]).to eq(I18n.t("picker.see_all"))
    expect(root["data-name-chips-see-all-title-value"]).to eq("Everyone")
  end

  it "renders a labelled text input without browser autocomplete" do
    input = rendered.at_css("input[type=text]")
    expect(input["name"]).to eq("transaction[contact_name]")
    expect(input["id"]).to eq("transaction_contact_name")
    expect(input["placeholder"]).to eq("A first name")
    expect(input["autocomplete"]).to eq("off")
    expect(rendered.at_css("label.form-label")["for"]).to eq("transaction_contact_name")
    expect(rendered.at_css("label").text).to eq("With whom?")
  end

  it "prepends its own render action to the caller's actions" do
    input = rendered.at_css("input[type=text]")
    expect(input["data-name-chips-target"]).to eq("input")
    expect(input["data-action"]).to eq("input->name-chips#render input->debt-fields#onPersonChange")
  end

  it "keeps the chips row hidden until the controller fills it" do
    chips = rendered.at_css(".name-chips")
    expect(chips["data-name-chips-target"]).to eq("chips")
    expect(chips.has_attribute?("hidden")).to be(true)
  end

  it "skips the see-all values and keeps the bare render action without extras" do
    rendered = render_inline(described_class.new(form: builder, field: :name, label: "Name", placeholder: "…"))
    root = rendered.at_css(".form-field")
    expect(root["data-name-chips-suggestions-value"]).to eq("[]")
    expect(root["data-name-chips-see-all-title-value"]).to be_nil
    expect(rendered.at_css("input[type=text]")["data-action"]).to eq("input->name-chips#render")
  end
end
