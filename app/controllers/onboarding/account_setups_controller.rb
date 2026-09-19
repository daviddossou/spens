# frozen_string_literal: true

class Onboarding::AccountSetupsController < OnboardingController
  before_action :authenticate_user!
  before_action :build_form, only: [ :show ]

  def show
    build_form
    track_onboarding_step_viewed("account_setup")
  end

  def update
    build_form(account_setup_params)

    if @form.submit
      track_accounts_opened
      redirect_to next_step_path, status: :see_other
    else
      track_onboarding_step_failed("account_setup", @form)
      render :show, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Error in Onboarding::AccountSetupsController#update: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to onboarding_account_setups_path, alert: t("onboarding.errors.generic"), status: :see_other
  end

  private

  def build_form(payload = {})
    @form ||= Onboarding::AccountSetupForm.new(current_space, payload)
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

  def track_accounts_opened
    created = @form.transactions.reject(&:should_skip?)
    created.each { Analytics.track(current_user, "transaction_created", source: "onboarding") }

    templates = created.filter_map { |line| account_template_key(line.account_name) }
    properties = { accounts: created.size, lines_skipped: @form.transactions.size - created.size,
                   account_templates: templates.uniq, custom_accounts: created.size - templates.size }
    track_onboarding_step_completed("account_setup", properties)
    track_onboarding_completed(properties)
  end

  # "mobile_money" for a suggested name in any locale, nil for a name the user typed:
  # custom names are personal and never leave the app.
  def account_template_key(name)
    @account_template_keys ||= I18n.available_locales.each_with_object({}) do |locale, keys|
      I18n.t("account_templates", locale: locale, default: {}).each { |key, label| keys[label.to_s.strip.downcase] = key.to_s }
    end
    @account_template_keys[name.to_s.strip.downcase]
  end

  def next_step_path
    current_space.reload
    Onboarding::StepNavigator.new(current_space).current_step_path
  end
end
