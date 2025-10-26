# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Onboarding::IncomeService do
  describe 'FREQUENCIES constant' do
    it 'is frozen' do
      expect(described_class::FREQUENCIES).to be_frozen
    end

    it 'contains all expected frequency values' do
      expect(described_class::FREQUENCIES).to eq(%w[weekly biweekly monthly quarterly yearly])
    end
  end

  describe 'SOURCES constant' do
    it 'is frozen' do
      expect(described_class::SOURCES).to be_frozen
    end

    it 'contains all expected source values' do
      expect(described_class::SOURCES).to eq(%w[salary business freelance investments pension other])
    end
  end

  describe '.frequency_options' do
    it 'returns all frequency options with translations' do
      options = described_class.frequency_options

      expect(options).to be_an(Array)
      expect(options.length).to eq(described_class::FREQUENCIES.length)
      expect(options.first).to be_an(Array)
      expect(options.first.length).to eq(2)
    end

    it 'returns options in translated label and value format' do
      options = described_class.frequency_options

      options.each do |option|
        expect(option[0]).to be_a(String)
        expect(option[1]).to be_a(String)
        expect(described_class::FREQUENCIES).to include(option[1])
      end
    end

    it 'uses I18n for labels' do
      I18n.with_locale(:en) do
        options = described_class.frequency_options
        expect(options.map(&:first)).to all(be_a(String))
      end
    end

    it 'returns different labels for different frequencies' do
      options = described_class.frequency_options
      labels = options.map(&:first)

      expect(labels.uniq.length).to eq(labels.length)
    end
  end

  describe '.source_options' do
    it 'returns all source options with translations' do
      options = described_class.source_options

      expect(options).to be_an(Array)
      expect(options.length).to eq(described_class::SOURCES.length)
      expect(options.first).to be_an(Array)
      expect(options.first.length).to eq(2)
    end

    it 'includes all defined sources' do
      options = described_class.source_options
      values = options.map(&:last)

      expect(values).to include('salary', 'business', 'freelance', 'investments', 'pension', 'other')
    end

    it 'uses I18n for labels' do
      I18n.with_locale(:en) do
        options = described_class.source_options
        expect(options.map(&:first)).to all(be_a(String))
      end
    end

    it 'returns different labels for different sources' do
      options = described_class.source_options
      labels = options.map(&:first)

      expect(labels.uniq.length).to eq(labels.length)
    end
  end

  describe '.valid_frequency?' do
    it 'returns true for valid frequencies' do
      expect(described_class.valid_frequency?('weekly')).to be true
      expect(described_class.valid_frequency?('monthly')).to be true
      expect(described_class.valid_frequency?('yearly')).to be true
    end

    it 'returns false for invalid frequencies' do
      expect(described_class.valid_frequency?('daily')).to be false
      expect(described_class.valid_frequency?('invalid')).to be false
    end

    it 'handles symbol input' do
      expect(described_class.valid_frequency?(:monthly)).to be true
    end

    it 'validates all FREQUENCIES constants' do
      described_class::FREQUENCIES.each do |frequency|
        expect(described_class.valid_frequency?(frequency)).to be true
      end
    end

    it 'returns false for nil' do
      expect(described_class.valid_frequency?(nil)).to be false
    end

    it 'returns false for empty string' do
      expect(described_class.valid_frequency?('')).to be false
    end
  end

  describe '.valid_source?' do
    it 'returns true for valid sources' do
      expect(described_class.valid_source?('salary')).to be true
      expect(described_class.valid_source?('business')).to be true
      expect(described_class.valid_source?('pension')).to be true
    end

    it 'returns false for invalid sources' do
      expect(described_class.valid_source?('invalid')).to be false
      expect(described_class.valid_source?('rental')).to be false
    end

    it 'handles symbol input' do
      expect(described_class.valid_source?(:salary)).to be true
    end

    it 'validates all SOURCES constants' do
      described_class::SOURCES.each do |source|
        expect(described_class.valid_source?(source)).to be true
      end
    end

    it 'returns false for nil' do
      expect(described_class.valid_source?(nil)).to be false
    end

    it 'returns false for empty string' do
      expect(described_class.valid_source?('')).to be false
    end
  end

  describe '.all_frequencies' do
    it 'returns array of frequency codes' do
      frequencies = described_class.all_frequencies

      expect(frequencies).to be_an(Array)
      expect(frequencies).to eq(%w[weekly biweekly monthly quarterly yearly])
    end

    it 'returns frozen array' do
      expect(described_class.all_frequencies).to be_frozen
    end

    it 'returns same as FREQUENCIES constant' do
      expect(described_class.all_frequencies).to eq(described_class::FREQUENCIES)
    end
  end

  describe '.all_sources' do
    it 'returns array of source codes' do
      sources = described_class.all_sources

      expect(sources).to be_an(Array)
      expect(sources).to eq(%w[salary business freelance investments pension other])
    end

    it 'returns frozen array' do
      expect(described_class.all_sources).to be_frozen
    end

    it 'returns same as SOURCES constant' do
      expect(described_class.all_sources).to eq(described_class::SOURCES)
    end
  end

  describe 'I18n support' do
    context 'with French locale' do
      around do |example|
        I18n.with_locale(:fr) { example.run }
      end

      it 'returns French frequency labels' do
        options = described_class.frequency_options

        expect(options).to be_an(Array)
        expect(options).not_to be_empty
      end

      it 'returns French source labels' do
        options = described_class.source_options

        expect(options).to be_an(Array)
        expect(options).not_to be_empty
      end
    end
  end
end
