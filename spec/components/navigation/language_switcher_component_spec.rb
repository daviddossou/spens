# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Navigation::LanguageSwitcherComponent, type: :component do
  describe "initialization" do
    it "inherits from Ui::SwitcherComponent" do
      component = described_class.new
      expect(component).to be_a(Ui::SwitcherComponent)
    end

    it "uses I18n defaults when no parameters provided" do
      allow(I18n).to receive(:locale).and_return(:en)
      allow(I18n).to receive(:available_locales).and_return([ :en, :fr ])

      component = described_class.new
      expect(component.instance_variable_get(:@current_locale)).to eq(:en)
      expect(component.instance_variable_get(:@available_locales)).to eq([ :en, :fr ])
    end

    it "accepts custom parameters" do
      component = described_class.new(
        current_locale: :fr,
        available_locales: [ :en, :fr, :es ],
        params: { page: 1 }
      )

      expect(component.instance_variable_get(:@current_locale)).to eq(:fr)
      expect(component.instance_variable_get(:@available_locales)).to eq([ :en, :fr, :es ])
      expect(component.instance_variable_get(:@params)).to eq({ page: 1 })
    end
  end

  describe "locale options generation" do
    let(:component) { described_class.new(current_locale: :en, available_locales: [ :en, :fr ]) }

    it "transforms available locales into switcher options format" do
      options = component.send(:locale_options)

      expect(options).to be_an(Array)
      expect(options.length).to eq(2)

      en_option = options.find { |opt| opt[:value] == :en }
      fr_option = options.find { |opt| opt[:value] == :fr }

      expect(en_option[:text]).to eq('EN')
      expect(en_option[:value]).to eq(:en)
      expect(en_option[:data]).to eq("turbo-method": "get")
      expect(en_option[:url]).to eq(locale: :en)

      expect(fr_option[:text]).to eq('FR')
      expect(fr_option[:value]).to eq(:fr)
    end

    it "converts locale symbols to uppercase text" do
      component = described_class.new(available_locales: [ :en, :es, :de ])
      options = component.send(:locale_options)

      texts = options.map { |opt| opt[:text] }
      expect(texts).to eq([ 'EN', 'ES', 'DE' ])
    end
  end

  describe "URL generation" do
    it "merges locale with existing parameters" do
      component = described_class.new(params: { page: 1, sort: 'name' })
      result = component.send(:locale_url, :fr)

      expect(result).to eq(page: 1, sort: 'name', locale: :fr)
    end

    it "handles ActionController::Parameters" do
      params = ActionController::Parameters.new(page: 1, sort: 'name')
      component = described_class.new(params: params)

      expect { component.send(:locale_url, :fr) }.not_to raise_error
    end

    it "works with empty parameters" do
      component = described_class.new(params: {})
      result = component.send(:locale_url, :es)

      expect(result).to eq(locale: :es)
    end
  end
end
