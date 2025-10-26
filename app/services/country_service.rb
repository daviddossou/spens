# frozen_string_literal: true

class CountryService
  PRIORITY_COUNTRIES = %w[BF CI SN ML NE TG BJ GN CM CD].freeze

  class << self
    def all
      ISO3166::Country.all.map do |country|
        [ country.translations[I18n.locale.to_s] || country.iso_short_name, country.alpha2 ]
      end.sort_by(&:first)
    end

    def priority
      PRIORITY_COUNTRIES.map do |code|
        country = ISO3166::Country.new(code)
        next unless country

        [ country.translations[I18n.locale.to_s] || country.iso_short_name, country.alpha2 ]
      end.compact
    end

    def find(code)
      ISO3166::Country.new(code)
    end

    def name_for(code)
      country = find(code)
      return nil unless country

      country.translations[I18n.locale.to_s] || country.iso_short_name
    end

    def priority?(code)
      PRIORITY_COUNTRIES.include?(code)
    end
  end
end
