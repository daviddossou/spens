# frozen_string_literal: true

class BudgetEntriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_budget_entry

  def edit
  end

  # Per-month override of the planned amount; the recurring rule is untouched.
  def update
    if @budget_entry.update(budget_entry_params)
      redirect_with_reload_to budgets_path(month: @budget_entry.month.strftime("%Y-%m")), notice: t(".success"), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_budget_entry
    @budget_entry = current_space.budget_entries.includes(:transaction_type, budget_item: [ :from_account, :to_account, :debt ]).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to budgets_path, alert: t("budgets.errors.not_found")
  end

  def budget_entry_params
    params.require(:budget_entry).permit(:planned_amount)
  end
end
