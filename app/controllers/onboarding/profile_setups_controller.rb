# frozen_string_literal: true

class Onboarding::ProfileSetupsController < OnboardingController
  before_action :authenticate_user!

  def show
    @form = build_form
    track_onboarding_step_viewed("profile_setup")
  end

  def update
    @form = build_form(profile_setup_params)

    if @form.submit
      track_onboarding_step_completed("profile_setup", Analytics.onboarding_answers(current_space.reload).except(:financial_goals))
      redirect_to next_step_path, status: :see_other
    else
      track_onboarding_step_failed("profile_setup", @form)
      render :show, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Error when updating profile setup: #{e.message}"
    redirect_to onboarding_profile_setups_path, alert: t("onboarding.errors.generic"), status: :see_other
  end

  private

  def build_form(payload = {})
    @form ||= Onboarding::ProfileSetupForm.new(current_space, payload)
  end

  def profile_setup_params
    params.require(:onboarding_profile_setup_form)
          .permit(:country, :currency, :income_frequency, :main_income_source)
  end

  def next_step_path
    current_space.reload
    Onboarding::StepNavigator.new(current_space).current_step_path
  end
end
