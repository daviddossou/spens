# frozen_string_literal: true

module Marketing
  # @label Locale picker
  class LocalePickerComponentPreview < ViewComponent::Preview
    COUNTRIES = [
      { code: "BJ", flag: "🇧🇯", name: "Bénin", cur: "XOF", lang: "FR" },
      { code: "CI", flag: "🇨🇮", name: "Côte d'Ivoire", cur: "XOF", lang: "FR" },
      { code: "NG", flag: "🇳🇬", name: "Nigeria", cur: "NGN", lang: "EN" },
      { code: "FR", flag: "🇫🇷", name: "France", cur: "EUR", lang: "FR" },
      { code: "INT", flag: "🌍", name: "International", cur: "USD", lang: "EN" }
    ].freeze

    # Closed, showing the first country
    def default
      render Marketing::LocalePickerComponent.new(countries: COUNTRIES)
    end

    # A single choice
    def single_country
      render Marketing::LocalePickerComponent.new(countries: COUNTRIES.last(1))
    end
  end
end
