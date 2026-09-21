# frozen_string_literal: true

class Onboarding::SavingsProjectionForm < BaseForm
  ##
  # Constants
  CURRENT_STEP = "onboarding_savings_projection"
  NEXT_STEP = "onboarding_account_setup"
  DEFAULT_INCOME = 150_000
  DEFAULT_RATE = 10
  RATE_RANGE = (1..40)

  ##
  # Attributes
  attr_reader :space, :guess

  attribute :monthly_income, :decimal
  attribute :savings_rate, :integer

  ##
  # Validations
  validates :monthly_income, numericality: { greater_than: 0 }
  validates :savings_rate, numericality: { only_integer: true, in: RATE_RANGE }

  def initialize(space, payload = {}, guess: nil)
    @space = space
    @guess = guess

    space.onboarding_current_step ||= CURRENT_STEP

    super(
      monthly_income: payload.key?(:monthly_income) ? digits(payload[:monthly_income]) : space.monthly_income || DEFAULT_INCOME,
      savings_rate: payload[:savings_rate] || space.savings_rate || DEFAULT_RATE
    )
  end

  def submit
    return false if invalid?

    space.assign_attributes(monthly_income: monthly_income, savings_rate: savings_rate,
                            onboarding_current_step: NEXT_STEP, **guessed_locale)

    if space.invalid?
      promote_errors(space.errors.messages)

      return false
    end

    space.save!
  rescue StandardError => e
    add_custom_error(:base, e.message)

    false
  end

  # The currency the amounts are shown in before the space has a confirmed one.
  def currency
    return space.currency if space.country.present?

    guess&.currency || space.currency || "XOF"
  end

  def monthly_saving
    (monthly_income.to_d * savings_rate.to_i / 100).round
  end

  private

  # The field shows "150 000"; keep the digits.
  def digits(value)
    value.to_s.gsub(/\D/, "").presence
  end

  # A guess never overwrites a country the space already has.
  def guessed_locale
    return {} if space.country.present? || guess&.country.blank?

    { country: guess.country, currency: guess.currency }.compact
  end
end
