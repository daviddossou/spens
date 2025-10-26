# frozen_string_literal: true

class Onboarding::ProfileSetupsController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_if_completed

  def show
    @form = build_form
  end

  def update
    @form = build_form(profile_setup_params)

    if @form.submit
      redirect_to next_step_path
    else
      render :show, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Error when updating profile setup: #{e.message}"
    redirect_to onboarding_profile_setups_path, alert: t('onboarding.errors.generic')
  end

  private

  def build_form(payload = {})
    @form ||= Onboarding::ProfileSetupForm.new(current_user, payload)
  end

  def profile_setup_params
    params.require(:onboarding_profile_setup_form)
          .permit(:country, :currency, :income_frequency, :main_income_source)
  end

  def redirect_if_completed
    redirect_to dashboard_path if current_user.onboarding_completed?
  end

  def next_step_path
    current_user.reload
    Onboarding::StepNavigator.new(current_user).current_step_path
  end
end
