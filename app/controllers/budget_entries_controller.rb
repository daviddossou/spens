# frozen_string_literal: true

class BudgetEntriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_budget_entry

  def edit
  end

  # One sheet, two scopes: "this month only" writes a per-month exception; "every
  # month from here" edits the recurring rule, taking effect from this month.
  def update
    params[:scope] == "rule" ? update_rule : update_month
  end

  # Rétablir — drop the exception and let the rule plan this month again.
  def revert
    @budget_entry.revert_to_rule!
    redirect_with_reload_to budgets_path(month: month_param), notice: t(".reverted"), status: :see_other
  end

  private

  def update_month
    if @budget_entry.override_to(params[:amount])
      redirect_with_reload_to budgets_path(month: month_param), notice: t(".success"), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update_rule
    # The edited month adopts the new rule, so it can't stay an exception.
    @budget_entry.update!(overridden: false, overridden_at: nil)
    @form = BudgetItemForm.new(current_space, rule_payload)

    if @form.submit
      redirect_with_reload_to budgets_path(month: month_param), notice: t(".rule_success"), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def rule_payload
    rule = params.fetch(:budget_item, {}).permit(:essential, :frequency, :ends_on, :rollover)
    rule.to_h.symbolize_keys.merge(
      budget_item: @budget_entry.budget_item,
      amount: params[:amount],
      effective_month: @budget_entry.month
    )
  end

  def set_budget_entry
    @budget_entry = current_space.budget_entries
                                 .includes(:transaction_type, budget_item: [ :from_account, :to_account, :debt ])
                                 .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to budgets_path, alert: t("budgets.errors.not_found")
  end

  def month_param
    @budget_entry.month.strftime("%Y-%m")
  end
end
