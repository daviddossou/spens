# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CountryService do
  describe 'PRIORITY_COUNTRIES constant' do
    it 'is frozen' do
      expect(described_class::PRIORITY_COUNTRIES).to be_frozen
    end

    it 'contains West African country codes' do
      expect(described_class::PRIORITY_COUNTRIES).to include('BF', 'CI', 'SN', 'ML', 'NE', 'TG', 'BJ', 'GN', 'CM', 'CD')
    end

    it 'contains only valid ISO country codes' do
      described_class::PRIORITY_COUNTRIES.each do |code|
        expect(ISO3166::Country.new(code)).not_to be_nil
      end
    end
  end

  describe '.all' do
    it 'returns all countries' do
      countries = described_class.all

      expect(countries).to be_an(Array)
      expect(countries).not_to be_empty
      expect(countries.first).to be_an(Array)
      expect(countries.first.length).to eq(2)
    end

    it 'returns countries sorted by name' do
      countries = described_class.all
      names = countries.map(&:first)

      expect(names).to eq(names.sort)
    end

    it 'includes major countries' do
      countries = described_class.all
      codes = countries.map(&:last)

      expect(codes).to include('US', 'FR', 'BF', 'CI')
    end

    it 'returns country name and code pairs' do
      countries = described_class.all
      us_entry = countries.find { |c| c.last == 'US' }

      expect(us_entry.first).to be_a(String)
      expect(us_entry.last).to eq('US')
    end

    it 'returns more than 200 countries' do
      countries = described_class.all
      expect(countries.length).to be > 200
    end

    context 'with French locale' do
      around do |example|
        I18n.with_locale(:fr) { example.run }
      end

      it 'returns localized country names' do
        countries = described_class.all
        france = countries.find { |c| c.last == 'FR' }

        expect(france.first).to eq('France')
      end

      it 'maintains alphabetical sorting in French' do
        countries = described_class.all
        names = countries.map(&:first)

        expect(names).to eq(names.sort)
      end
    end
  end

  describe '.priority' do
    it 'returns priority countries' do
      countries = described_class.priority

      expect(countries).to be_an(Array)
      expect(countries.length).to eq(described_class::PRIORITY_COUNTRIES.length)
    end

    it 'maintains priority order' do
      countries = described_class.priority
      codes = countries.map(&:last)

      expect(codes).to eq(described_class::PRIORITY_COUNTRIES)
    end

    it 'includes West African countries' do
      countries = described_class.priority
      codes = countries.map(&:last)

      expect(codes).to include('BF', 'CI', 'SN', 'ML')
    end

    it 'returns all priority countries with names and codes' do
      countries = described_class.priority

      countries.each do |country|
        expect(country).to be_an(Array)
        expect(country.length).to eq(2)
        expect(country.first).to be_a(String)
        expect(country.last).to be_a(String)
      end
    end

    it 'does not include non-priority countries' do
      countries = described_class.priority
      codes = countries.map(&:last)

      expect(codes).not_to include('US', 'FR', 'GB')
    end

    context 'with French locale' do
      around do |example|
        I18n.with_locale(:fr) { example.run }
      end

      it 'returns localized priority country names' do
        countries = described_class.priority
        burkina = countries.find { |c| c.last == 'BF' }

        expect(burkina.first).to eq('Burkina Faso')
      end

      it 'maintains priority order regardless of locale' do
        countries = described_class.priority
        codes = countries.map(&:last)

        expect(codes).to eq(described_class::PRIORITY_COUNTRIES)
      end
    end
  end

  describe '.find' do
    it 'finds a country by code' do
      country = described_class.find('US')

      expect(country).to be_a(ISO3166::Country)
      expect(country.alpha2).to eq('US')
    end

    it 'returns nil for invalid code' do
      country = described_class.find('XX')

      expect(country).to be_nil
    end

    it 'handles lowercase country codes' do
      country = described_class.find('us')

      expect(country).to be_a(ISO3166::Country)
      expect(country.alpha2).to eq('US')
    end

    it 'finds priority countries' do
      described_class::PRIORITY_COUNTRIES.each do |code|
        country = described_class.find(code)
        expect(country).to be_a(ISO3166::Country)
        expect(country.alpha2).to eq(code)
      end
    end

    it 'returns country with full data' do
      country = described_class.find('US')

      expect(country.iso_short_name).to be_present
      expect(country.translations).to be_a(Hash)
    end
  end

  describe '.name_for' do
    it 'returns country name' do
      name = described_class.name_for('FR')

      expect(name).to eq('France')
    end

    it 'returns nil for invalid code' do
      name = described_class.name_for('XX')

      expect(name).to be_nil
    end

    it 'returns names for all priority countries' do
      described_class::PRIORITY_COUNTRIES.each do |code|
        name = described_class.name_for(code)
        expect(name).to be_a(String)
        expect(name).not_to be_empty
      end
    end

    it 'handles lowercase country codes' do
      name = described_class.name_for('us')

      expect(name).to be_a(String)
      expect(name).to eq('United States')
    end

    context 'with English locale' do
      around do |example|
        I18n.with_locale(:en) { example.run }
      end

      it 'returns English country name' do
        name = described_class.name_for('FR')

        expect(name).to eq('France')
      end

      it 'returns English name for Burkina Faso' do
        name = described_class.name_for('BF')

        expect(name).to eq('Burkina Faso')
      end
    end

    context 'with French locale' do
      around do |example|
        I18n.with_locale(:fr) { example.run }
      end

      it 'returns localized country name' do
        name = described_class.name_for('FR')

        expect(name).to eq('France')
      end

      it 'returns French name for United States' do
        name = described_class.name_for('US')

        # ISO3166 translations or iso_short_name
        expect(name).to be_a(String)
        expect(name).not_to be_empty
      end
    end

    context 'with nil code' do
      it 'returns nil' do
        name = described_class.name_for(nil)

        expect(name).to be_nil
      end
    end
  end

  describe '.priority?' do
    it 'returns true for priority countries' do
      expect(described_class.priority?('BF')).to be true
      expect(described_class.priority?('CI')).to be true
    end

    it 'returns false for non-priority countries' do
      expect(described_class.priority?('US')).to be false
      expect(described_class.priority?('FR')).to be false
    end

    it 'returns true for all PRIORITY_COUNTRIES' do
      described_class::PRIORITY_COUNTRIES.each do |code|
        expect(described_class.priority?(code)).to be true
      end
    end

    it 'is case-sensitive (requires uppercase codes)' do
      expect(described_class.priority?('bf')).to be false
      expect(described_class.priority?('BF')).to be true
    end

    it 'returns false for invalid codes' do
      expect(described_class.priority?('XX')).to be false
      expect(described_class.priority?(nil)).to be false
      expect(described_class.priority?('')).to be false
    end
  end

  describe 'integration' do
    it 'priority countries are subset of all countries' do
      all_codes = described_class.all.map(&:last)
      priority_codes = described_class.priority.map(&:last)

      priority_codes.each do |code|
        expect(all_codes).to include(code)
      end
    end

    it 'priority countries can be found individually' do
      described_class::PRIORITY_COUNTRIES.each do |code|
        country = described_class.find(code)
        name = described_class.name_for(code)

        expect(country).not_to be_nil
        expect(name).not_to be_nil
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
