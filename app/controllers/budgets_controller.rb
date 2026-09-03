# frozen_string_literal: true

class BudgetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_month

  def index
    Budgets::EnsureEntriesService.new(space: current_space, month: @month).call
    load_budget_data
  end

  # Legacy finished-month route: fold into the Budget page (Bilan mode).
  def summary
    redirect_to budgets_path(month: params[:month]), status: :moved_permanently
  end

  private

  # Each month has a default mode from its position in time, and a set of modes
  # it can be *read* as. The banner is a viewpoint selector on the SAME month —
  # it never navigates — so a `view` param overrides the default, clamped to the
  # readings that make sense: a future month has no "realised" to show, a closed
  # month has no "in progress".
  def load_mode_data
    current_bom = Date.current.beginning_of_month

    if @month > current_bom
      default_mode = :plan
      @allowed_modes = [ :plan ]
    elsif @month < current_bom
      default_mode = :wrap_up
      @allowed_modes = [ :plan, :wrap_up ]
    else
      default_mode = :live
      @allowed_modes = [ :plan, :live, :wrap_up ]
    end

    requested = params[:view]&.to_sym
    @mode = @allowed_modes.include?(requested) ? requested : default_mode

    # Editable only when it's the current-or-future month and not being read as a
    # (hypothetical or closed) balance sheet.
    @editable = @mode != :wrap_up && @month >= current_bom

    # The month's contextual subtitle is about the month itself, not the reading.
    @month_position = @month > current_bom ? :future : (@month < current_bom ? :past : :current)
    @days_in_month = @month.end_of_month.day
    case @month_position
    when :future
      @days_until = (@month - Date.current).to_i
    when :current
      @day_of_month = Date.current.day
      @days_remaining = @days_in_month - @day_of_month
    end

    # The one hero figure — « Épargne du mois » — reads differently per mode:
    # planned (the plan), à ce stade (the projection minus off-plan), finale.
    @hero_value = case @mode
    when :plan then @projected_net
    when :wrap_up then @actual_net
    else @projected_outcome + @offplan_net
    end

    # A transfer between everyday accounts is neutral, but one INTO a set-aside
    # account is not: it turns free money into committed money. It never leaves
    # the hero — moving money to savings is keeping it — but it is no longer
    # available to spend, so the page states it. Coming back out of savings, the
    # same line credits it back.
    set_aside_ids = current_space.accounts.set_aside.pluck(:id)
    @committed_to_goals = @sections[:transfer].sum do |entry|
      item = entry.budget_item
      amount = @mode == :wrap_up ? @actuals_by_entry[entry] : entry.planned_amount
      into = set_aside_ids.include?(item.to_account_id) ? amount : 0
      back = set_aside_ids.include?(item.from_account_id) ? amount : 0
      into - back
    end
    @free_value = @hero_value - @committed_to_goals
  end

  def set_month
    # Strict parse: Date.parse("-01") on a missing param "succeeds" off the
    # system clock, bypassing the user's time zone at month boundaries.
    @month = (parse_month(params[:month]) || Date.current.beginning_of_month)
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

    # Vital / Confort: the expense section split by whether a line is essential.
    # Vital is the floor you can't skip; Confort is what's adjustable. This is a
    # breakdown of planned expenses — not income minus the floor (that's savings).
    essential_expense = @sections[:expense].select { |e| e.budget_item.essential }
    comfort_expense = @sections[:expense].reject { |e| e.budget_item.essential }
    @planned_vital = essential_expense.sum(&:planned_amount)
    @planned_confort = comfort_expense.sum(&:planned_amount)
    @planned_expense_total = @planned_vital + @planned_confort
    @actual_vital = essential_expense.sum { |e| @actuals_by_entry[e] }
    @actual_confort = comfort_expense.sum { |e| @actuals_by_entry[e] }
    # What's left to spend against the whole expense plan, and a daily pace.
    @reste_a_depenser = @planned_expense_total - (@actual_vital + @actual_confort)

    @actual_income = income_entries.sum { |e| @actuals_by_entry[e] }
    @actual_expense = expense_entries.sum { |e| @actuals_by_entry[e] }
    @actual_net = @actual_income - @actual_expense

    # Projected month outcome given reality so far: what already moved plus
    # what the plan still expects (a fulfilled line contributes nothing more;
    # overspending is already inside the actuals). Starts equal to the plan
    # and degrades as the month diverges — this is what the savings-goal
    # badge tracks. A past month has nothing left to expect.
    @past_month = @month < Date.current.beginning_of_month
    remaining_income = income_entries.sum { |e| [ e.planned_amount - @actuals_by_entry[e], 0 ].max }
    remaining_expense = expense_entries.sum { |e| [ e.planned_amount - @actuals_by_entry[e], 0 ].max }
    @projected_outcome = @past_month ? @actual_net : @actual_net + remaining_income - remaining_expense

    @unplanned = Budgets::UnplannedActivityQuery.new(space: current_space, month: @month).call

    # Off-plan movements shift the projection: unplanned income lifts it,
    # unplanned spending (the common case) drags it down.
    @unplanned_income_total = @unplanned[:income].values.sum { |s| s[:amount] }
    @unplanned_expense_total = @unplanned[:expense].values.sum { |s| s[:amount] }
    @offplan_net = @unplanned_income_total - @unplanned_expense_total

    @has_items = current_space.budget_items.active.exists?

    load_mode_data
  end
end
