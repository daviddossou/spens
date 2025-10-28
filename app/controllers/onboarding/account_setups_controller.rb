# frozen_string_literal: true

class Onboarding::AccountSetupsController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_if_completed
  before_action :build_form, only: [ :show ]

  def show
    build_form
  end

  def update
    build_form(account_setup_params)

    if @form.submit
      redirect_to next_step_path
    else
      render :show, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Error in Onboarding::AccountSetupsController#update: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to onboarding_account_setups_path, alert: t("onboarding.errors.generic")
  end

  private

  def build_form(payload = {})
    @form ||= Onboarding::AccountSetupForm.new(current_user, payload)
  end

  def account_setup_params
    params.require(:onboarding_account_setup_form).permit(
      transactions_attributes: [
        :amount, :transaction_date,
        account_attributes: [ :name ],
        transaction_type_attributes: [ :name, :kind ]
      ]
    )
  end

  def redirect_if_completed
    redirect_to dashboard_path if current_user.onboarding_completed?
  end

  def next_step_path
    current_user.reload
    Onboarding::StepNavigator.new(current_user).current_step_path
  end
end
