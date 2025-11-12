class Onboarding::FinancialGoalsController < OnboardingController
  before_action :authenticate_user!
  before_action :build_form, only: [ :show ]

  # GET /onboarding/financial_goals
  def show ; end

  # PATCH/PUT /onboarding/financial_goals
  def update
    build_form(financial_goals_params)

    if @form.submit
      redirect_to next_step_path
    else
      render :show, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "Error when updating financial goals: #{e.message}"
    redirect_to onboarding_financial_goals_path, alert:  t("onboarding.errors.generic")
  end

  private

  def build_form(payload = {})
    @form ||= Onboarding::FinancialGoalForm.new(current_user, payload)
  end

  def financial_goals_params
    params.require(:onboarding_financial_goal_form).permit(
      financial_goals: []
    )
  end

  def next_step_path
    current_user.reload
    Onboarding::StepNavigator.new(current_user).current_step_path
  end
end
