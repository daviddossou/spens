# frozen_string_literal: true

class Onboarding::IncomeService
  FREQUENCIES = %w[weekly biweekly monthly quarterly yearly].freeze
  SOURCES = %w[salary business freelance investments pension other].freeze

  class << self
    def frequency_options
      FREQUENCIES.map do |frequency|
        [ I18n.t("onboarding.income_frequencies.#{frequency}"), frequency ]
      end
    end

    def source_options
      SOURCES.map do |source|
        [ I18n.t("onboarding.income_sources.#{source}"), source ]
      end
    end

    def valid_frequency?(frequency)
      FREQUENCIES.include?(frequency.to_s)
    end

    def valid_source?(source)
      SOURCES.include?(source.to_s)
    end

    def all_frequencies
      FREQUENCIES
    end

    def all_sources
      SOURCES
    end
  end
end
