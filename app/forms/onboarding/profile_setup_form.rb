# frozen_string_literal: true

class Onboarding::ProfileSetupForm < BaseForm
  ##
  # Constants
  CURRENT_STEP = "onboarding_profile_setup"
  NEXT_STEP = "onboarding_account_setup"

  ##
  # Attributes
  attr_accessor :space

  attribute :country, :string
  attribute :currency, :string
  attribute :income_frequency, :string
  attribute :main_income_source, :string
  attribute :monthly_savings_goal, :decimal

  ##
  # Validations
  validates :country, presence: true
  validates :currency, presence: true, inclusion: { in: Space::CURRENCIES }
  validates :income_frequency, inclusion: { in: Space::INCOME_FREQUENCIES }, allow_blank: true
  validates :monthly_savings_goal, numericality: { greater_than: 0 }, allow_nil: true

  def initialize(space, payload = {})
    @space = space

    space.onboarding_current_step ||= CURRENT_STEP

    super(
      country: payload[:country] || space.country,
      currency: payload[:currency] || space.currency || "XOF",
      income_frequency: payload[:income_frequency] || space.income_frequency,
      main_income_source: payload[:main_income_source] || space.main_income_source,
      monthly_savings_goal: payload[:monthly_savings_goal].presence || space.monthly_savings_goal
    )
  end

  def submit
    return false if invalid?

    space.assign_attributes(
      country: country,
      currency: currency,
      income_frequency: income_frequency,
      main_income_source: main_income_source,
      monthly_savings_goal: monthly_savings_goal,
      onboarding_current_step: NEXT_STEP
    )

    if space.invalid?
      promote_errors(space.errors.messages)

      return false
    end

    space.save!
  rescue StandardError => e
    add_custom_error(:base, e.message)

    false
  end

  attr_reader :space
end
