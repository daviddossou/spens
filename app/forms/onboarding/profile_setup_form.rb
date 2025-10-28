# frozen_string_literal: true

class Onboarding::ProfileSetupForm < BaseForm
  ##
  # Constants
  CURRENT_STEP = "onboarding_profile_setup"
  NEXT_STEP = "onboarding_account_setup"

  ##
  # Attributes
  attr_accessor :user

  attribute :country, :string
  attribute :currency, :string
  attribute :income_frequency, :string
  attribute :main_income_source, :string

  ##
  # Validations
  validates :country, presence: true
  validates :currency, presence: true, inclusion: { in: User::CURRENCIES }
  validates :income_frequency, inclusion: { in: User::INCOME_FREQUENCIES }, allow_blank: true

  def initialize(user, payload = {})
    @user = user

    user.onboarding_current_step ||= CURRENT_STEP

    super(
      country: payload[:country] || user.country,
      currency: payload[:currency] || user.currency || "XOF",
      income_frequency: payload[:income_frequency] || user.income_frequency,
      main_income_source: payload[:main_income_source] || user.main_income_source
    )
  end

  def submit
    return false if invalid?

    user.assign_attributes(
      country: country,
      currency: currency,
      income_frequency: income_frequency,
      main_income_source: main_income_source,
      onboarding_current_step: NEXT_STEP
    )

    if user.invalid?
      promote_errors(user.errors.messages)

      return false
    end

    user.save!
  rescue StandardError => e
    add_custom_error(:base, e.message)

    false
  end

  attr_reader :user
end
