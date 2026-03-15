class AnalyticsController < ApplicationController
  before_action :authenticate_user!

  PERIODS = %w[custom today yesterday this_week this_month last_3_months last_6_months last_12_months all_time].freeze

  def index
    @currency = current_space.currency
    @period = params[:period].presence_in(PERIODS) || "this_month"
    @date_range = compute_date_range

    load_income_expense_data
    load_debts_data
    load_savings_data
  end

  private

  def compute_date_range
    case @period
    when "today"
      Date.current..Date.current
    when "yesterday"
      Date.yesterday..Date.yesterday
    when "this_week"
      Date.current.beginning_of_week..Date.current.end_of_week
    when "this_month"
      Date.current.all_month
    when "last_3_months"
      3.months.ago.to_date..Date.current
    when "last_6_months"
      6.months.ago.to_date..Date.current
    when "last_12_months"
      12.months.ago.to_date..Date.current
    when "all_time"
      nil
    when "custom"
      start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.current.beginning_of_month
      end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current
      start_date..end_date
    end
  rescue Date::Error
    Date.current.all_month
  end

  # ─── Income / Expense tab ───────────────────────────────────────────

  def load_income_expense_data
    # Exclude internal transfers which are not income or expense
    transactions = scoped_transactions

    # Include debt_in (repayment received) as income, debt_out (repayment given) as expense
    income_tx = transactions.joins(:transaction_type).where(transaction_types: { kind: %w[income debt_in] })
    expense_tx = transactions.joins(:transaction_type).where(transaction_types: { kind: %w[expense debt_out] })

    @total_income = income_tx.sum(:amount).abs
    @total_expenses = expense_tx.sum(:amount).abs
    @net = @total_income - @total_expenses

    # Income by category (doughnut)
    @income_by_category = income_tx
      .joins(:transaction_type)
      .group("transaction_types.name")
      .sum(:amount)
      .transform_values(&:abs)
      .sort_by { |_, v| -v }.to_h

    # Expense by category (doughnut)
    @expense_by_category = expense_tx
      .joins(:transaction_type)
      .group("transaction_types.name")
      .sum(:amount)
      .transform_values(&:abs)
      .sort_by { |_, v| -v }.to_h

    # Net cash flow trend (line) — group by month or day depending on period
    @income_trend = group_by_period(income_tx).transform_values(&:abs)
    @expense_trend = group_by_period(expense_tx).transform_values(&:abs)

    # Top spending categories (bar) — top 5
    @top_spending = @expense_by_category.first(5).to_h
  end

  # ─── Debts tab ──────────────────────────────────────────────────────

  def load_debts_data
    @debts_lent = current_space.debts.lent
    @debts_borrowed = current_space.debts.borrowed

    @total_owed_to_me = @debts_lent.ongoing.sum("total_lent - total_reimbursed")
    @total_i_owe = @debts_borrowed.ongoing.sum("total_lent - total_reimbursed")

    # People who owe me (doughnut) — ongoing lent debts
    @owed_to_me_by_person = @debts_lent.ongoing
      .pluck(:name, Arel.sql("total_lent - total_reimbursed"))
      .to_h
      .select { |_, v| v > 0 }
      .sort_by { |_, v| -v }.to_h

    # What I owe (doughnut) — ongoing borrowed debts
    @i_owe_by_person = @debts_borrowed.ongoing
      .pluck(:name, Arel.sql("total_lent - total_reimbursed"))
      .to_h
      .select { |_, v| v > 0 }
      .sort_by { |_, v| -v }.to_h

    # Debt repayment trend (line) — debt-related transactions over time
    debt_in_tx = scoped_transactions.joins(:transaction_type).where(transaction_types: { kind: "debt_in" })
    debt_out_tx = scoped_transactions.joins(:transaction_type).where(transaction_types: { kind: "debt_out" })

    @debt_in_trend = group_by_period(debt_in_tx).transform_values(&:abs)
    @debt_out_trend = group_by_period(debt_out_tx).transform_values(&:abs)

    @total_debts_count = current_space.debts.ongoing.count
    @paid_debts_count = current_space.debts.paid.count
  end

  # ─── Savings tab ────────────────────────────────────────────────────

  def load_savings_data
    @accounts = current_space.accounts
    @total_balance = @accounts.sum(:balance)

    # Account balance distribution (doughnut)
    @account_balances = @accounts
      .where("balance > 0")
      .pluck(:name, :balance)
      .sort_by { |_, v| -v }.to_h

    # Accounts with saving goals
    @saving_accounts = @accounts.with_saving_goals.order(:name)
    @total_saving_goal = @saving_accounts.sum(:saving_goal)
    @total_saved = @saving_accounts.sum(:balance)

    # Monthly saving trend (line) — net amount going into accounts
    saving_tx = scoped_transactions.joins(:account)
    @saving_trend = group_by_period(saving_tx)

    # Goal progress data
    @goals_progress = @saving_accounts.map do |account|
      {
        name: account.name,
        balance: account.balance,
        goal: account.saving_goal,
        progress: account.saving_goal > 0 ? ((account.balance / account.saving_goal) * 100).clamp(0, 100).round : 0
      }
    end
  end

  # ─── Shared helpers ─────────────────────────────────────────────────

  def scoped_transactions
    base = current_space.transactions
    @date_range ? base.where(transaction_date: @date_range) : base
  end

  def group_by_period(relation)
    if @date_range.nil?
      relation.group_by_month(:transaction_date, format: "%b %Y").sum(:amount)
    else
      range_days = (@date_range.last - @date_range.first).to_i

      if range_days <= 31
        relation.group_by_day(:transaction_date, range: @date_range).sum(:amount)
      elsif range_days <= 366
        relation.group_by_month(:transaction_date, range: @date_range, format: "%b").sum(:amount)
      else
        relation.group_by_month(:transaction_date, format: "%b %Y").sum(:amount)
      end
    end
  end
end
