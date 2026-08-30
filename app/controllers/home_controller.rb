class HomeController < ApplicationController
  # This will be renamed in the future to handle transaction data
  # For now, it manages the main authentication flow

  before_action :authenticate_user!, only: [ :show ]

  def index
    if user_signed_in?
      redirect_to dashboard_path
    else
      redirect_to landing_path
    end
  end

  def show
    # Analytics
    @currency = current_space.currency
    @total_balance = current_space.accounts.sum(:balance)
    @set_aside_total = current_space.accounts.set_aside.sum(:balance)

    # Two verifiable facts, not one interpreted "savings" figure. Transfers are
    # excluded (the same money would count twice); each is shown on its own.
    month_scope = current_space.transactions
      .joins(:transaction_type)
      .where(transaction_date: Date.current.all_month)
    @money_in = month_scope.where(transaction_types: { kind: %w[income debt_in] }).sum(:amount).abs
    @money_out = month_scope.where(transaction_types: { kind: %w[expense debt_out] }).sum(:amount).abs

    @owed_to_me = current_space.debts.ongoing.lent.sum("total_lent - total_reimbursed")
    @i_owe = current_space.debts.ongoing.borrowed.sum("total_lent - total_reimbursed")

    # Transactions timeline (paginated + date-grouped for infinite scroll)
    @search_query = params[:q].to_s.strip
    scope = current_space.transactions
    scope = scope.search(@search_query) if @search_query.present?
    load_transactions_timeline(scope)

    respond_to do |format|
      format.html
      format.turbo_stream if @page > 1
    end
  end
end
