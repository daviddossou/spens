# frozen_string_literal: true

module Admin
  class SpacesController < BaseController
    def index
      scope = Space.includes(:user, :memberships).order(created_at: :desc)
      scope = scope.where("name ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:q])}%") if params[:q].present?
      @spaces = paginate(scope)
    end

    def show
      @space = Space.find(params[:id])
      @members = @space.members
      @accounts = @space.accounts
      @transaction_types_count = @space.transaction_types.count
      @recent_transactions = @space.transactions.includes(:transaction_type, :account, :space)
                                   .order(transaction_date: :desc, created_at: :desc).limit(10)
      @transactions_count = @space.transactions.count
    end
  end
end
