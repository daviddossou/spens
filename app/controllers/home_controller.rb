class HomeController < ApplicationController
  # This will be renamed in the future to handle transaction data
  # For now, it manages the main authentication flow

  before_action :authenticate_user!, only: [ :show ]

  def index
    if user_signed_in?
      redirect_to dashboard_path
    else
      redirect_to new_user_registration_path
    end
  end

  def show
    # Analytics
    @currency = current_space.currency
    @total_balance = current_space.accounts.sum(:balance)
    @saved_this_month = current_space.transactions
      .joins(:transaction_type)
      .where(transaction_date: Date.current.all_month)
      .where.not(transaction_types: { kind: %w[transfer transfer_in transfer_out] })
      .where.not(account_id: nil)
      .sum(:amount)
    @owed_to_me = current_space.debts.ongoing.lent.sum("total_lent - total_reimbursed")
    @i_owe = current_space.debts.ongoing.borrowed.sum("total_lent - total_reimbursed")

    # Transactions timeline (paginated + date-grouped for infinite scroll)
    load_transactions_timeline(current_space.transactions)

    respond_to do |format|
      format.html
      format.turbo_stream if @page > 1
    end
  end
end
