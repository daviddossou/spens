class Onboarding::FinancialGoalForm < BaseForm
  ##
  # Constants
  CURRENT_STEP = "onboarding_financial_goal"
  NEXT_STEP = "onboarding_profile_setup"

  ##
  # Attributes
  attr_accessor :space, :financial_goals

  ##
  # Validations
  validates :financial_goals, presence: true
  validate :goals_are_allowed

  def initialize(space, payload = {})
    self.space = space

    self.financial_goals = payload.key?(:financial_goals) ? payload[:financial_goals] : space.financial_goals

    space.onboarding_current_step ||= CURRENT_STEP

    super()
  end

  def submit
    return false if invalid?

    space.assign_attributes(financial_goals: financial_goals, onboarding_current_step: NEXT_STEP)

    if space.invalid?
      promote_errors(space.errors.messages)

      return false
    end

    space.save!
  rescue => e
    add_custom_error(:base, e.message)

    false
  end

  def available_goals
    Space::FINANCIAL_GOALS.map do |goal|
      {
        key: goal,
        name: I18n.t("financial_goals.#{goal}.name", default: goal.humanize),
        description: I18n.t("financial_goals.#{goal}.description", default: "")
      }
    end
  end

  private

  def goals_are_allowed
    return if financial_goals.blank?
    invalid = financial_goals - Space::FINANCIAL_GOALS
    return if invalid.empty?
    add_custom_error(:financial_goals, I18n.t("onboarding.validations.invalid_goal", goals: invalid.join(", ")))
  end
end
