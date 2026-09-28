# frozen_string_literal: true

# Step 3, "your money": one balance per account the day's expenses created, plus any other
# place the user keeps money. Validating it ends the onboarding data; the summary follows.
class Onboarding::BalancesController < OnboardingController
  def show
    @form = build_form
    load_context
    track_onboarding_step_viewed("balances")
  end

  def update
    @form = build_form(balances_params)

    if @form.submit
      properties = { accounts: current_space.accounts.active.count, extra_accounts: @form.extra.size,
                     expenses: expenses.count }
      track_onboarding_step_completed("balances", properties)
      track_onboarding_completed(properties)
      redirect_to onboarding_summaries_path, status: :see_other
    else
      load_context
      track_onboarding_step_failed("balances", @form)
      render :show, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Error in Onboarding::BalancesController#update: #{e.message}"
    redirect_to onboarding_balances_path, alert: t("onboarding.errors.generic"), status: :see_other
  end

  private

  def build_form(payload = {})
    Onboarding::BalancesForm.new(current_space, user: current_user, payload: payload)
  end

  # What each account already spent, and the places not used yet, for the chips.
  def load_context
    @spent = expenses.group(:account_id).sum(:amount).transform_values(&:abs)
    @suggestions = AccountSuggestionsService.new(current_space).template_names
  end

  def expenses
    current_space.transactions.joins(:transaction_type).where(transaction_types: { kind: "expense" })
  end

  def balances_params
    params.fetch(:balances, {}).permit(balances: {}, extra: [ :name, :amount ]).to_h.deep_symbolize_keys
  end
end
