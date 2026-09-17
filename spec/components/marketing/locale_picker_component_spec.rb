# frozen_string_literal: true

require "rails_helper"

RSpec.describe Marketing::LocalePickerComponent, type: :component do
  let(:countries) do
    [
      { code: "BJ", flag: "🇧🇯", name: "Bénin", cur: "XOF", lang: "FR" },
      { code: "NG", flag: "🇳🇬", name: "Nigeria", cur: "NGN", lang: "EN" },
      { code: "INT", flag: "🌍", name: "International", cur: "USD", lang: "EN" }
    ]
  end
  let(:rendered) { render_inline(described_class.new(countries: countries)) }
  let(:picker) { rendered.at_css(".landing-picker") }

  it "hands the list to the picker controller as JSON" do
    expect(picker["data-controller"]).to eq("landing--locale-picker")
    expect(JSON.parse(picker["data-landing--locale-picker-countries-value"]).map { |c| c["code"] }).to eq(%w[BJ NG INT])
  end

  it "opens a listbox from a button showing the first country" do
    button = picker.at_css("button.landing-picker__button")
    expect(button["type"]).to eq("button")
    expect(button["aria-haspopup"]).to eq("listbox")
    expect(button["data-action"]).to eq("landing--locale-picker#toggle")
    expect(button["data-landing--locale-picker-target"]).to eq("button")
    expect(button.at_css('[data-landing--locale-picker-target="flag"]').text).to eq("🇧🇯")
    expect(button.at_css('[data-landing--locale-picker-target="flag"]')["aria-hidden"]).to eq("true")
    expect(button.at_css('[data-landing--locale-picker-target="code"]').text).to eq("XOF")
  end

  it "keeps the menu hidden until toggled" do
    menu = picker.at_css(".landing-picker__menu")
    expect(menu["data-landing--locale-picker-target"]).to eq("menu")
    expect(menu.attributes).to have_key("hidden")
    expect(menu.at_css(".landing-picker__title").text).to eq(I18n.t("landing.nav.picker_title"))
  end

  it "lists one pickable item per country with its code, language and currency" do
    items = picker.css("button.landing-picker__item")
    expect(items.size).to eq(3)
    expect(items.map { |i| i["data-action"] }.uniq).to eq([ "landing--locale-picker#pick" ])
    expect(items.map { |i| i["data-code"] }).to eq(%w[BJ NG INT])
    expect(items.map { |i| i.at_css(".landing-picker__name").text }).to eq([ "Bénin", "Nigeria", "International" ])
    expect(items.last.at_css(".landing-picker__meta").text).to eq("EN · USD")
    expect(items.map { |i| i.at_css(".landing-picker__flag")["aria-hidden"] }.uniq).to eq([ "true" ])
  end

  %i[fr en].each do |locale|
    it "reads in #{locale}" do
      I18n.with_locale(locale) do
        html = render_inline(described_class.new(countries: countries))
        expect(html.css(".translation_missing")).to be_empty
        expect(html.at_css(".landing-picker__title").text).to eq(I18n.t("landing.nav.picker_title"))
      end
    end
  end
end
