# frozen_string_literal: true

require "rails_helper"

RSpec.describe Onboarding::ProfileSetups::PickerFieldComponent, type: :component do
  let(:space) { Space.new(country: "BJ", currency: "XOF") }
  let(:form_object) { Onboarding::ProfileSetupForm.new(space) }
  let(:builder) { ActionView::Helpers::FormBuilder.new("onboarding_profile_setup_form", form_object, vc_test_controller.view_context, {}) }

  describe ".rows_for" do
    it "puts the priority countries first, then the rest alphabetically, as flat rows" do
      rows = described_class.rows_for(:country)
      priority_codes = CountryService::PRIORITY_COUNTRIES
      expect(rows.first(priority_codes.size).map { |r| r[:value] }).to eq(priority_codes)
      rest = rows.drop(priority_codes.size)
      expect(rest.map { |r| r[:label] }).to eq(rest.map { |r| r[:label] }.sort)
      expect(rows.map { |r| r[:value] }.uniq.size).to eq(rows.size)
      expect(rows).to all(match(value: kind_of(String), label: kind_of(String)))
    end

    it "lists the income frequencies without a priority group" do
      rows = described_class.rows_for(:income_frequency)
      expect(rows.map { |r| r[:value] }).to eq(Onboarding::IncomeService::FREQUENCIES)
      expect(rows.first[:label]).to eq(I18n.t("onboarding.income_frequencies.#{rows.first[:value]}"))
    end
  end

  it "labels the question from i18n and shows the stored answer" do
    rendered = render_inline(described_class.new(form: builder, field: :country))
    root = rendered.at_css(".form-field")
    expect(rendered.at_css("label.form-label").text).to eq(I18n.t("onboarding.profile_setups.picker_field_component.country_label"))
    expect(rendered.at_css(".form-help-text").text).to eq(I18n.t("onboarding.profile_setups.picker_field_component.country_help"))
    expect(root["data-picker-title-value"]).to eq(I18n.t("onboarding.profile_setups.picker_field_component.country_label"))
    expect(root["data-picker-placeholder-value"]).to eq(I18n.t("onboarding.profile_setups.picker_field_component.placeholder"))
    expect(root["data-picker-allow-create-value"]).to eq("false")
    expect(rendered.at_css("input[type=hidden]")["name"]).to eq("onboarding_profile_setup_form[country]")
    expect(rendered.at_css("input[type=hidden]")["value"]).to eq("BJ")
    expect(rendered.at_css(".picker__value").text).to eq(CountryService.name_for("BJ"))
    expect(rendered.to_html).not_to include("translation_missing")
  end

  it "shows the placeholder for an unanswered question" do
    rendered = render_inline(described_class.new(form: builder, field: :income_frequency))
    label = rendered.at_css(".picker__value")
    expect(label.text).to eq(I18n.t("onboarding.profile_setups.picker_field_component.placeholder"))
    expect(label["class"]).to include("picker__value--empty")
    expect(JSON.parse(rendered.at_css(".form-field")["data-picker-rows-value"]).size).to eq(Onboarding::IncomeService::FREQUENCIES.size)
  end

  it "lets the caller override picker options" do
    rendered = render_inline(described_class.new(form: builder, field: :currency, id: "currency-picker", field_data: { profile_prefill_target: "currency" }))
    expect(rendered.at_css(".form-field")["id"]).to eq("currency-picker")
    expect(rendered.at_css("input[type=hidden]")["data-profile-prefill-target"]).to eq("currency")
  end
end
