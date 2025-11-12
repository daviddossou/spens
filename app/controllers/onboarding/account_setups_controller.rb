# frozen_string_literal: true

class Onboarding::AccountSetupsController < OnboardingController
  before_action :authenticate_user!
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
        :account_name,
        :amount,
        :transaction_date,
        :transaction_type_name,
        :transaction_type_kind
      ]
    )
  end

  def next_step_path
    current_user.reload
    Onboarding::StepNavigator.new(current_user).current_step_path
  end
end
