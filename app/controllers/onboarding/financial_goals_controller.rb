class Onboarding::FinancialGoalsController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_if_completed
  before_action :build_form, only: [ :show ]

  # GET /onboarding/financial_goals
  def show ; end

  # PATCH/PUT /onboarding/financial_goals
  def update
    build_form(financial_goals_params)

    if @form.submit
      redirect_to next_onboarding_step
    else
      render :show, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "Error when updating financial goals: #{e.message}"
    redirect_to onboarding_financial_goals_path, alert: "Something went wrong. Please try again."
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

  def redirect_if_completed
    redirect_to dashboard_path if current_user.onboarding_completed?
  end

  def next_onboarding_step
    current_user.reload
    Onboarding::StepNavigator.new(current_user).next_step_path
  end
end
