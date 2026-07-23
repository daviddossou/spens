# frozen_string_literal: true

class BudgetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_month

  def index
    Budgets::EnsureEntriesService.new(space: current_space, month: @month).call
    load_budget_data
  end

  # Read-only balance-sheet view for a finished month.
  def summary
    Budgets::EnsureEntriesService.new(space: current_space, month: @month).call
    load_budget_data
  end

  private

  def set_month
    @month = begin
      Date.parse("#{params[:month]}-01")
    rescue ArgumentError, TypeError
      Date.current
    end.beginning_of_month
  end

  def load_budget_data
    entries = current_space.budget_entries.for_month(@month)
                           .includes(:transaction_type, budget_item: [ :from_account, :to_account, :debt ])
                           .sort_by { |e| e.display_name.to_s }

    @sections = {
      income: entries.select { |e| e.kind == "income" },
      expense: entries.select { |e| e.kind == "expense" },
      transfer: entries.select { |e| e.kind == "transfer" },
      debt: entries.select { |e| BudgetItem::DEBT_KINDS.include?(e.kind) }
    }

    actuals = Budgets::ActualsQuery.new(space: current_space, month: @month)
    @actuals_by_entry = entries.index_with { |e| actuals.for_entry(e) }

    # Transfers are internal movements: excluded from the net. Debt movements
    # count like the dashboard counts them (in with income, out with expenses).
    # Actuals are scoped to the budgeted lines so plan and execution compare 1:1.
    income_entries = @sections[:income] + @sections[:debt].select { |e| e.kind == "debt_in" }
    expense_entries = @sections[:expense] + @sections[:debt].select { |e| e.kind == "debt_out" }

    @planned_income = income_entries.sum(&:planned_amount)
    @planned_expense = expense_entries.sum(&:planned_amount)
    @projected_net = @planned_income - @planned_expense

    @actual_income = income_entries.sum { |e| @actuals_by_entry[e] }
    @actual_expense = expense_entries.sum { |e| @actuals_by_entry[e] }
    @actual_net = @actual_income - @actual_expense

    @savings_goal = current_space.monthly_savings_goal.to_f
    @past_month = @month < Date.current.beginning_of_month
    @has_items = current_space.budget_items.active.exists?
  end
end
