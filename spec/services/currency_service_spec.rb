# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CurrencyService do
  describe 'PRIORITY_CURRENCIES constant' do
    it 'is frozen' do
      expect(described_class::PRIORITY_CURRENCIES).to be_frozen
    end

    it 'contains West African and major currencies' do
      expect(described_class::PRIORITY_CURRENCIES).to include('XOF', 'XAF', 'EUR', 'USD', 'GBP')
    end

    it 'contains only valid currency codes' do
      described_class::PRIORITY_CURRENCIES.each do |code|
        expect(Money::Currency.new(code)).to be_a(Money::Currency)
      end
    end
  end

  describe '.all' do
    it 'returns all currencies' do
      currencies = described_class.all

      expect(currencies).to be_an(Array)
      expect(currencies).not_to be_empty
      expect(currencies.first).to be_an(Array)
      expect(currencies.first.length).to eq(2)
    end

    it 'returns currencies sorted by display name' do
      currencies = described_class.all
      displays = currencies.map(&:first)

      expect(displays).to eq(displays.sort)
    end

    it 'includes major currencies' do
      currencies = described_class.all
      codes = currencies.map(&:last)

      expect(codes).to include('USD', 'EUR', 'XOF', 'GBP')
    end

    it 'formats display as "Name (CODE)"' do
      currencies = described_class.all
      display = currencies.find { |c| c.last == 'USD' }.first

      expect(display).to match(/\(.+\)$/)
      expect(display).to include('USD')
    end

    it 'returns more than 100 currencies' do
      currencies = described_class.all
      expect(currencies.length).to be > 100
    end

    context 'with French locale' do
      around do |example|
        I18n.with_locale(:fr) { example.run }
      end

      it 'uses localized names in display' do
        currencies = described_class.all
        xof = currencies.find { |c| c.last == 'XOF' }

        expect(xof.first).to include('XOF')
      end
    end
  end

  describe '.priority' do
    it 'returns priority currencies' do
      currencies = described_class.priority

      expect(currencies).to be_an(Array)
      expect(currencies.length).to eq(described_class::PRIORITY_CURRENCIES.length)
    end

    it 'maintains priority order' do
      currencies = described_class.priority
      codes = currencies.map(&:last)

      expect(codes).to eq(described_class::PRIORITY_CURRENCIES)
    end

    it 'includes West African currencies' do
      currencies = described_class.priority
      codes = currencies.map(&:last)

      expect(codes).to include('XOF', 'XAF')
    end

    it 'formats each priority currency as display pairs' do
      currencies = described_class.priority

      currencies.each do |display, code|
        expect(display).to include(code)
        expect(display).to match(/\(.+\)$/)
      end
    end

    it 'handles UnknownCurrency errors gracefully' do
      expect { described_class.priority }.not_to raise_error
    end
  end

  describe '.find' do
    it 'finds a currency by code' do
      currency = described_class.find('USD')

      expect(currency).to be_a(Money::Currency)
      expect(currency.iso_code).to eq('USD')
    end

    it 'returns nil for invalid code' do
      currency = described_class.find('XXX')

      expect(currency).to be_nil
    end

    it 'handles lowercase codes' do
      currency = described_class.find('usd')

      expect(currency).to be_a(Money::Currency)
      expect(currency.iso_code).to eq('USD')
    end

    it 'finds all priority currencies' do
      described_class::PRIORITY_CURRENCIES.each do |code|
        currency = described_class.find(code)
        expect(currency).to be_a(Money::Currency)
        expect(currency.iso_code).to eq(code)
      end
    end

    it 'returns currency with full data' do
      currency = described_class.find('USD')

      expect(currency.name).to be_present
      expect(currency.symbol).to be_present
    end
  end

  describe '.name_for' do
    it 'returns currency name' do
      name = described_class.name_for('USD')

      expect(name).to be_a(String)
      expect(name).not_to be_empty
    end

    it 'returns nil for invalid code' do
      name = described_class.name_for('XXX')

      expect(name).to be_nil
    end

    it 'returns names for all priority currencies' do
      described_class::PRIORITY_CURRENCIES.each do |code|
        name = described_class.name_for(code)
        expect(name).to be_a(String)
        expect(name).not_to be_empty
      end
    end

    context 'with English locale' do
      around do |example|
        I18n.with_locale(:en) { example.run }
      end

      it 'returns English currency name' do
        name = described_class.name_for('USD')

        expect(name).to be_a(String)
      end
    end

    context 'with French locale' do
      around do |example|
        I18n.with_locale(:fr) { example.run }
      end

      it 'returns localized currency name for XOF' do
        name = described_class.name_for('XOF')

        expect(name).to eq("Franc CFA d'Afrique de l'Ouest")
      end

      it 'returns localized currency name for EUR' do
        name = described_class.name_for('EUR')

        expect(name).to eq('Euro')
      end
    end
  end

  describe '.format_display' do
    it 'formats currency as "Name (CODE)"' do
      display = described_class.format_display('USD')

      expect(display).to match(/^.+ \(USD\)$/)
    end

    it 'returns nil for invalid code' do
      display = described_class.format_display('XXX')

      expect(display).to be_nil
    end

    context 'with French locale' do
      around do |example|
        I18n.with_locale(:fr) { example.run }
      end

      it 'uses localized name' do
        display = described_class.format_display('XOF')

        expect(display).to eq("Franc CFA d'Afrique de l'Ouest (XOF)")
      end
    end
  end

  describe '.priority?' do
    it 'returns true for priority currencies' do
      expect(described_class.priority?('XOF')).to be true
      expect(described_class.priority?('EUR')).to be true
    end

    it 'returns false for non-priority currencies' do
      expect(described_class.priority?('JPY')).to be false
      expect(described_class.priority?('CAD')).to be false
    end

    it 'returns true for all PRIORITY_CURRENCIES' do
      described_class::PRIORITY_CURRENCIES.each do |code|
        expect(described_class.priority?(code)).to be true
      end
    end

    it 'is case-sensitive (requires uppercase codes)' do
      expect(described_class.priority?('xof')).to be false
      expect(described_class.priority?('XOF')).to be true
    end

    it 'returns false for invalid codes' do
      expect(described_class.priority?('XXX')).to be false
      expect(described_class.priority?(nil)).to be false
      expect(described_class.priority?('')).to be false
    end
  end

  describe '.all_codes' do
    it 'returns array of currency codes' do
      codes = described_class.all_codes

      expect(codes).to be_an(Array)
      expect(codes).to all(be_a(String))
      expect(codes).to include('USD', 'EUR', 'XOF')
    end

    it 'returns same count as .all' do
      expect(described_class.all_codes.length).to eq(described_class.all.length)
    end

    it 'returns sorted codes' do
      codes = described_class.all_codes
      expect(codes).to eq(codes.sort)
    end

    it 'includes all priority currencies' do
      codes = described_class.all_codes
      described_class::PRIORITY_CURRENCIES.each do |priority_code|
        expect(codes).to include(priority_code)
      end
    end
  end

  describe 'integration' do
    it 'priority currencies are subset of all currencies' do
      all_codes = described_class.all_codes
      priority_codes = described_class.priority.map(&:last)

      priority_codes.each do |code|
        expect(all_codes).to include(code)
      end
    end

    it 'priority currencies can be found individually' do
      described_class::PRIORITY_CURRENCIES.each do |code|
        currency = described_class.find(code)
        name = described_class.name_for(code)
        display = described_class.format_display(code)

        expect(currency).not_to be_nil
        expect(name).not_to be_nil
        expect(display).not_to be_nil
      end
    end

    it 'maintains consistent data structure across methods' do
      all_sample = described_class.all.first
      priority_sample = described_class.priority.first

      expect(all_sample.length).to eq(priority_sample.length)
      expect(all_sample.first).to be_a(String)
      expect(all_sample.last).to be_a(String)
    end
  end
end
