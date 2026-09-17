# frozen_string_literal: true

require "rails_helper"

RSpec.describe Forms::PickerLayerComponent, type: :component do
  let(:rendered) { render_inline(described_class.new) }
  let(:root) { rendered.at_css("#picker-layer") }

  it "mounts a hidden picker-layer controller with its localized values" do
    expect(root["data-controller"]).to eq("picker-layer")
    expect(root["data-picker-layer-target"]).to eq("root")
    expect(root.has_attribute?("hidden")).to be(true)
    expect(root["data-picker-layer-create-label-value"]).to eq(I18n.t("picker.create"))
    expect(root["data-picker-layer-empty-value"]).to eq(I18n.t("picker.empty"))
    expect(root["data-picker-layer-planned-value"]).to eq(I18n.t("picker.group_planned"))
    expect(root["data-picker-layer-rest-value"]).to eq(I18n.t("picker.group_rest"))
    expect(rendered.to_html).not_to include("translation_missing")
  end

  it "renders the head with a labelled back button, a title and a step" do
    back = root.at_css("button.picker-layer__back")
    expect(back["type"]).to eq("button")
    expect(back["aria-label"]).to eq(I18n.t("picker.back"))
    expect(back["data-action"]).to eq("picker-layer#back")
    expect(root.at_css("h2.picker-layer__title")["data-picker-layer-target"]).to eq("title")
    expect(root.at_css(".picker-layer__step")["data-picker-layer-target"]).to eq("step")
  end

  it "renders a search field that filters as you type" do
    search = root.at_css("input[type=search]")
    expect(search["data-picker-layer-target"]).to eq("search")
    expect(search["data-action"]).to eq("input->picker-layer#filter")
    expect(search["autocomplete"]).to eq("off")
    expect(search["placeholder"]).to eq(I18n.t("picker.search"))
  end

  it "renders the hidden context recap and the empty list" do
    expect(root.at_css(".picker-layer__context").has_attribute?("hidden")).to be(true)
    expect(root.at_css(".picker-layer__context")["data-picker-layer-target"]).to eq("context")
    list = root.at_css("ul.picker-layer__list")
    expect(list["data-picker-layer-target"]).to eq("list")
    expect(list.children).to be_empty
  end
end
