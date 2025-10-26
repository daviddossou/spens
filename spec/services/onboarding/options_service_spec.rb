# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::OptionsService do
  describe '.options_for' do
    context 'with :country field' do
      it 'returns country options from CountryService' do
        options = described_class.options_for(:country)

        expect(options).to be_an(Array)
        expect(options).not_to be_empty
        expect(options.first).to be_an(Array)
        expect(options.first.length).to eq(2)
      end

      it 'returns all countries' do
        options = described_class.options_for(:country)
        codes = options.map(&:last)

        expect(codes).to include('US', 'FR', 'BF', 'CI')
      end
    end

    context 'with :currency field' do
      it 'returns currency options from CurrencyService' do
        options = described_class.options_for(:currency)

        expect(options).to be_an(Array)
        expect(options).not_to be_empty
        expect(options.first).to be_an(Array)
        expect(options.first.length).to eq(2)
      end

      it 'returns all currencies' do
        options = described_class.options_for(:currency)
        codes = options.map(&:last)

        expect(codes).to include('USD', 'EUR', 'XOF')
      end
    end

    context 'with :income_frequency field' do
      it 'returns frequency options from IncomeService' do
        options = described_class.options_for(:income_frequency)

        expect(options).to be_an(Array)
        expect(options.length).to eq(Onboarding::IncomeService::FREQUENCIES.length)
      end

      it 'returns translated frequency options' do
        options = described_class.options_for(:income_frequency)
        values = options.map(&:last)

        expect(values).to include('weekly', 'monthly', 'yearly')
      end
    end

    context 'with :main_income_source field' do
      it 'returns source options from IncomeService' do
        options = described_class.options_for(:main_income_source)

        expect(options).to be_an(Array)
        expect(options.length).to eq(Onboarding::IncomeService::SOURCES.length)
      end

      it 'returns translated source options' do
        options = described_class.options_for(:main_income_source)
        values = options.map(&:last)

        expect(values).to include('salary', 'business', 'freelance')
      end
    end

    context 'with unknown field' do
      it 'returns empty array' do
        options = described_class.options_for(:unknown_field)

        expect(options).to eq([])
      end

      it 'returns empty array for nil' do
        options = described_class.options_for(nil)

        expect(options).to eq([])
      end
    end
  end

  describe '.priority_options_for' do
    context 'with :country field' do
      it 'returns priority countries' do
        options = described_class.priority_options_for(:country)

        expect(options).to be_an(Array)
        expect(options).not_to be_empty
      end

      it 'returns West African priority countries' do
        options = described_class.priority_options_for(:country)
        codes = options.map(&:last)

        expect(codes).to include('BF', 'CI', 'SN')
      end

      it 'maintains priority order' do
        options = described_class.priority_options_for(:country)
        codes = options.map(&:last)

        expect(codes).to eq(CountryService::PRIORITY_COUNTRIES)
      end
    end

    context 'with :currency field' do
      it 'returns priority currencies' do
        options = described_class.priority_options_for(:currency)

        expect(options).to be_an(Array)
        expect(options).not_to be_empty
      end

      it 'returns West African and major currencies' do
        options = described_class.priority_options_for(:currency)
        codes = options.map(&:last)

        expect(codes).to include('XOF', 'XAF', 'EUR', 'USD')
      end

      it 'maintains priority order' do
        options = described_class.priority_options_for(:currency)
        codes = options.map(&:last)

        expect(codes).to eq(CurrencyService::PRIORITY_CURRENCIES)
      end
    end

    context 'with non-priority fields' do
      it 'returns nil for :income_frequency' do
        options = described_class.priority_options_for(:income_frequency)

        expect(options).to be_nil
      end

      it 'returns nil for :main_income_source' do
        options = described_class.priority_options_for(:main_income_source)

        expect(options).to be_nil
      end

      it 'returns nil for unknown field' do
        options = described_class.priority_options_for(:unknown_field)

        expect(options).to be_nil
      end
    end
  end

  describe '.searchable?' do
    it 'returns true for :country' do
      expect(described_class.searchable?(:country)).to be true
    end

    it 'returns true for :currency' do
      expect(described_class.searchable?(:currency)).to be true
    end

    it 'returns false for :income_frequency' do
      expect(described_class.searchable?(:income_frequency)).to be false
    end

    it 'returns false for :main_income_source' do
      expect(described_class.searchable?(:main_income_source)).to be false
    end

    it 'returns false for unknown field' do
      expect(described_class.searchable?(:unknown_field)).to be false
    end

    it 'returns false for nil' do
      expect(described_class.searchable?(nil)).to be false
    end

    it 'returns false for string keys' do
      expect(described_class.searchable?('country')).to be false
    end
  end

  describe 'integration with underlying services' do
    it 'country options match CountryService.all' do
      options = described_class.options_for(:country)
      country_options = CountryService.all

      expect(options).to eq(country_options)
    end

    it 'currency options match CurrencyService.all' do
      options = described_class.options_for(:currency)
      currency_options = CurrencyService.all

      expect(options).to eq(currency_options)
    end

    it 'frequency options match IncomeService.frequency_options' do
      options = described_class.options_for(:income_frequency)
      frequency_options = Onboarding::IncomeService.frequency_options

      expect(options).to eq(frequency_options)
    end

    it 'source options match IncomeService.source_options' do
      options = described_class.options_for(:main_income_source)
      source_options = Onboarding::IncomeService.source_options

      expect(options).to eq(source_options)
    end

    it 'priority country options match CountryService.priority' do
      options = described_class.priority_options_for(:country)
      priority_options = CountryService.priority

      expect(options).to eq(priority_options)
    end

    it 'priority currency options match CurrencyService.priority' do
      options = described_class.priority_options_for(:currency)
      priority_options = CurrencyService.priority

      expect(options).to eq(priority_options)
    end
  end

  describe 'data structure consistency' do
    it 'all options return [label, value] pairs' do
      [:country, :currency, :income_frequency, :main_income_source].each do |field|
        options = described_class.options_for(field)

        options.each do |option|
          expect(option).to be_an(Array)
          expect(option.length).to eq(2)
          expect(option.first).to be_a(String)
          expect(option.last).to be_a(String)
        end
      end
    end

    it 'priority options return [label, value] pairs when present' do
      [:country, :currency].each do |field|
        options = described_class.priority_options_for(field)

        next if options.nil?

        options.each do |option|
          expect(option).to be_an(Array)
          expect(option.length).to eq(2)
          expect(option.first).to be_a(String)
          expect(option.last).to be_a(String)
        end
      end
    end
  end

  describe 'localization support' do
    context 'with French locale' do
      around do |example|
        I18n.with_locale(:fr) { example.run }
      end

      it 'returns localized frequency options' do
        options = described_class.options_for(:income_frequency)

        expect(options).to be_an(Array)
        expect(options).not_to be_empty
      end

      it 'returns localized source options' do
        options = described_class.options_for(:main_income_source)

        expect(options).to be_an(Array)
        expect(options).not_to be_empty
      end
    end
  end
end
