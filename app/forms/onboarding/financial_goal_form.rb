class Onboarding::FinancialGoalForm < BaseForm
  ##
  # Attributes
  attr_accessor :user, :financial_goals

  ##
  # Validations
  validates :financial_goals, presence: true
  validate :goals_are_allowed

  CURRENT_STEP = "onboarding_financial_goal"
  NEXT_STEP = "onboarding_personal_info"

  def initialize(user, payload = {})
    self.user = user

    self.financial_goals = payload.key?(:financial_goals) ? payload[:financial_goals] : user.financial_goals

    user.onboarding_current_step ||= CURRENT_STEP

    super()
  end

  def submit
    return false if invalid?

    user.assign_attributes(financial_goals: financial_goals, onboarding_current_step: NEXT_STEP)

    unless user.valid?
      promote_errors(user.errors.messages)

      return false
    end

    user.save!
  rescue => e
    add_custom_error(:base, e.message)

    false
  end

  def available_goals
    User::FINANCIAL_GOALS.map do |goal|
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
    invalid = financial_goals - User::FINANCIAL_GOALS
    return if invalid.empty?
    add_custom_error(:financial_goals, I18n.t("onboarding.validations.invalid_goal", goals: invalid.join(", ")))
  end
end
