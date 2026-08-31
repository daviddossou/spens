# frozen_string_literal: true

class BudgetItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_budget_item, only: [ :edit, :update, :destroy ]

  def new
    @form = BudgetItemForm.new(current_space, kind: params[:kind], starts_on: month_param,
                                              transaction_type_name: params[:transaction_type_name],
                                              from_account_name: params[:from_account_name],
                                              to_account_name: params[:to_account_name],
                                              amount: params[:amount])
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
    # Removal takes effect from a given month (default: now); earlier months keep
    # their history. From a started month you drop it "from next month" so the
    # month you're on keeps the spending already logged against it.
    from = parse_month(params[:from_month]) || Date.current.beginning_of_month

    ActiveRecord::Base.transaction do
      if from <= Date.current.beginning_of_month
        @budget_item.update!(active: false)
      else
        # Removing from a future month: bound the rule so it stops there and no
        # new months materialize, while earlier months keep their history.
        @budget_item.update!(ends_on: from.prev_month.end_of_month)
      end
      @budget_item.budget_entries.where(month: from..).destroy_all
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
    parse_month(params[:month]) || Date.current.beginning_of_month
  end

  # Reads a "YYYY-MM" slug or a full date; nil when absent or malformed.
  def parse_month(value)
    return nil if value.blank?

    (value.match?(/\A\d{4}-\d{2}\z/) ? Date.parse("#{value}-01") : Date.parse(value)).beginning_of_month
  rescue Date::Error, TypeError
    nil
  end

  def month_slug(date)
    date.strftime("%Y-%m")
  end

  def budget_item_params
    params.require(:budget_item).permit(:kind, :transaction_type_name, :from_account_name, :to_account_name, :contact_name, :amount, :frequency, :starts_on, :ends_on, :rollover, :essential)
  end
end
