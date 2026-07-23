# frozen_string_literal: true

class BudgetItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_budget_item, only: [ :edit, :update, :destroy ]

  def new
    @form = BudgetItemForm.new(current_space, kind: params[:kind], starts_on: month_param)
    @form.user = current_user
  end

  def create
    @form = BudgetItemForm.new(current_space, budget_item_params.to_h.symbolize_keys)
    @form.user = current_user

    if @form.submit
      redirect_with_reload_to budgets_path(month: month_slug(@form.starts_on)), notice: t(".success"), status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @form = BudgetItemForm.new(current_space, budget_item: @budget_item)
    @form.user = current_user
  end

  def update
    @form = BudgetItemForm.new(current_space, budget_item_params.to_h.symbolize_keys.merge(budget_item: @budget_item))
    @form.user = current_user

    if @form.submit
      redirect_with_reload_to budgets_path(month: params[:month].presence), notice: t(".success"), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Stops the plan going forward: deactivate the rule and drop unsettled
  # current/future entries; paid entries and past months stay as history.
  def destroy
    ActiveRecord::Base.transaction do
      @budget_item.update!(active: false)
      @budget_item.budget_entries.where(month: Date.current.beginning_of_month..).destroy_all
    end

    redirect_with_reload_to budgets_path(month: params[:month].presence), notice: t(".success"), status: :see_other
  end

  private

  def set_budget_item
    @budget_item = current_space.budget_items.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to budgets_path, alert: t("budgets.errors.not_found")
  end

  def month_param
    Date.parse("#{params[:month]}-01").beginning_of_month
  rescue ArgumentError, TypeError
    Date.current.beginning_of_month
  end

  def month_slug(date)
    date.strftime("%Y-%m")
  end

  def budget_item_params
    params.require(:budget_item).permit(:kind, :transaction_type_name, :from_account_name, :to_account_name, :contact_name, :amount, :frequency, :starts_on)
  end
end
