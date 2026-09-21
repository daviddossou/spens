# frozen_string_literal: true

# Step 2, "gather your money": the accounts list inside the onboarding chrome. Accounts are
# added one at a time through the real new-account sheet (AccountsController).
class Onboarding::AccountSetupsController < OnboardingController
  NEXT_STEP = "onboarding_first_day"
  STOPPED = "onboarding_completed"

  def show
    load_accounts
    track_onboarding_step_viewed("account_setup")
  end

  # Moves on, with or without accounts ("I don't have my accounts on me"), or stops here.
  def update
    current_space.update!(onboarding_current_step: stopping? ? STOPPED : NEXT_STEP)
    track_step_left

    redirect_to Onboarding::StepNavigator.new(current_space).current_step_path, status: :see_other
  rescue StandardError => e
    Rails.logger.error "Error in Onboarding::AccountSetupsController#update: #{e.message}"
    redirect_to onboarding_account_setups_path, alert: t("onboarding.errors.generic"), status: :see_other
  end

  private

  def stopping?
    params[:stop].present?
  end

  def load_accounts
    accounts = current_space.accounts.active.includes(:goal).sort_by { |account| -account.balance }
    @set_aside, @everyday = accounts.partition { |account| account.set_aside? || account.goal.present? }
    @total = accounts.sum(&:balance)
  end

  def track_step_left
    names = current_space.accounts.active.pluck(:name)
    templates = names.filter_map { |name| account_template_key(name) }
    properties = { accounts: names.size, skipped: names.empty?, stopped_here: stopping?,
                   account_templates: templates.uniq, custom_accounts: names.size - templates.size }

    track_onboarding_step_completed("account_setup", properties)
    track_onboarding_completed(properties) if stopping?
  end

  # "mobile_money" for a suggested name in any locale, nil for a name the user typed:
  # custom names are personal and never leave the app.
  def account_template_key(name)
    @account_template_keys ||= I18n.available_locales.each_with_object({}) do |locale, keys|
      I18n.t("account_templates", locale: locale, default: {}).each { |key, label| keys[label.to_s.strip.downcase] = key.to_s }
    end
    @account_template_keys[name.to_s.strip.downcase]
  end
end
