class HomeController < ApplicationController
  # This will be renamed in the future to handle transaction data
  # For now, it manages the main authentication flow

  before_action :authenticate_user!, only: [ :dashboard ]

  def index
    # Landing page - redirect based on authentication status
    if user_signed_in?
      redirect_to dashboard_path
    else
      # Redirect unauthenticated users to Devise signup page
      redirect_to new_user_registration_path
    end
  end

  def dashboard
    @page = params[:page]&.to_i || 1
    @per_page = 20

    # Get transactions ordered by date (most recent first)
    @transactions = current_user.transactions
      .includes(:transaction_type, :account, :debt)
      .order(transaction_date: :desc, created_at: :desc)
      .offset((@page - 1) * @per_page)
      .limit(@per_page)

    # Group transactions by date for display
    @grouped_transactions = @transactions.group_by(&:transaction_date)

    # Check if there are more transactions
    @has_more = current_user.transactions.count > (@page * @per_page)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end
end
