# frozen_string_literal: true

MoneyRails.configure do |config|
  # Set default currency
  config.default_currency = :xof

  # Register a custom currency if needed
  # config.register_currency = {
  #   priority: 1,
  #   iso_code: "XXX",
  #   name: "Custom Currency",
  #   symbol: "X",
  #   subunit: "Cent",
  #   subunit_to_unit: 100,
  #   decimal_mark: ".",
  #   thousands_separator: ","
  # }

  # Set default bank object
  config.default_bank = Money::Bank::VariableExchange.new(Money::RatesStore::Memory.new)

  # Add exchange rates manually if needed (optional)
  # config.default_bank.add_rate("USD", "EUR", 0.85)

  # Use I18n localization for currency names
  config.locale_backend = :i18n

  # Set default formatting options
  config.no_cents_if_whole = false
  config.include_validations = true
end
