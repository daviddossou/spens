class Onboarding::FinancialGoalsController < OnboardingController
  before_action :build_form, only: [ :show ]

  # GET /onboarding/financial_goals
  def show
    track_onboarding_step_viewed("financial_goal")
  end

  # PATCH/PUT /onboarding/financial_goals
  def update
    build_form(financial_goals_params)

    if @form.submit
      track_goals_chosen
      redirect_to next_step_path, status: :see_other
    else
      track_onboarding_step_failed("financial_goal", @form)
      render :show, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "Error when updating financial goals: #{e.message}"
    redirect_to onboarding_financial_goals_path, alert:  t("onboarding.errors.generic"), status: :see_other
  end

  private

  def build_form(payload = {})
    @form ||= Onboarding::FinancialGoalForm.new(current_space, payload)
  end

  def financial_goals_params
    params.require(:onboarding_financial_goal_form).permit(
      financial_goals: []
    )
  end

  # landing_goals: the problems the landing diagnostic pre-ticked (set by the Stimulus
  # controller), so we know whether the diagnostic carried over and whether it was changed.
  def track_goals_chosen
    goals = @form.financial_goals
    from_landing = params[:landing_goals].to_s.split(",") & Space::FINANCIAL_GOALS

    track_onboarding_goals(goals, from_landing: from_landing)
    track_onboarding_step_completed("financial_goal",
                                    goals: goals, goals_count: goals.size, goals_from_landing: from_landing,
                                    goals_changed_from_landing: from_landing.any? && from_landing.sort != goals.sort)
  end

  def next_step_path
    current_space.reload
    Onboarding::StepNavigator.new(current_space).current_step_path
  end
end
