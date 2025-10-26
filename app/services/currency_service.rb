# frozen_string_literal: true

# Service to provide currency-related options and data
class CurrencyService
  PRIORITY_CURRENCIES = %w[XOF XAF EUR USD GBP].freeze

  class << self
    def all
      Money::Currency.all.map do |currency|
        [ format_display(currency.iso_code), currency.iso_code ]
      end.sort_by { |display, _code| display }
    end

    def priority
      PRIORITY_CURRENCIES.map do |currency_code|
        [ format_display(currency_code), currency_code ]
      rescue Money::Currency::UnknownCurrency
        [ currency_code, currency_code ]
      end
    end

    def find(code)
      Money::Currency.new(code)
    rescue Money::Currency::UnknownCurrency
      nil
    end

    def name_for(code)
      currency = find(code)
      return nil unless currency

      I18n.t("currencies.#{code}", default: currency.name)
    end

    def format_display(code)
      name = name_for(code)
      return nil unless name

      "#{name} (#{code})"
    end

    def all_codes
      Money::Currency.all.map(&:iso_code).sort
    end

    def priority?(code)
      PRIORITY_CURRENCIES.include?(code)
    end
  end
end
