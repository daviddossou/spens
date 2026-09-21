# frozen_string_literal: true

class Onboarding::SavingsProjectionsController < OnboardingController
  def show
    @form = build_form
    track_onboarding_step_viewed("savings_projection")
  end

  def update
    @form = build_form(savings_projection_params)

    if @form.submit
      # No amounts leave the app: the rate is a preference, the income is not sent.
      track_onboarding_step_completed("savings_projection",
                                      savings_rate: @form.savings_rate, country: current_space.country,
                                      currency: current_space.currency)
      redirect_to next_step_path, status: :see_other
    else
      track_onboarding_step_failed("savings_projection", @form)
      render :show, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Error when updating savings projection: #{e.message}"
    redirect_to onboarding_savings_projections_path, alert: t("onboarding.errors.generic"), status: :see_other
  end

  private

  def build_form(payload = {})
    Onboarding::SavingsProjectionForm.new(current_space, payload, guess: locale_guess)
  end

  def locale_guess
    Onboarding::LocaleGuess.new(request: request, picked_country: params[:landing_country],
                                picked_currency: params[:landing_currency],
                                time_zone: params[:time_zone].presence || current_user.time_zone)
  end

  def savings_projection_params
    params.require(:onboarding_savings_projection_form).permit(:monthly_income, :savings_rate)
  end

  def next_step_path
    Onboarding::StepNavigator.new(current_space.reload).current_step_path
  end
end
