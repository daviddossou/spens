# frozen_string_literal: true

class Onboarding::OptionsService
  class << self
    def options_for(field)
      case field
      when :country
        CountryService.all
      when :currency
        CurrencyService.all
      when :income_frequency
        Onboarding::IncomeService.frequency_options
      when :main_income_source
        Onboarding::IncomeService.source_options
      else
        []
      end
    end

    def priority_options_for(field)
      case field
      when :country
        CountryService.priority
      when :currency
        CurrencyService.priority
      else
        nil
      end
    end

    def searchable?(field)
      %i[country currency].include?(field)
    end
  end
end
