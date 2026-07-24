# frozen_string_literal: true

module Admin
  class TransactionsController < BaseController
    def index
      scope = Transaction.includes(:transaction_type, :account, :space, :user)
                         .order(transaction_date: :desc, created_at: :desc)
      scope = scope.where(space_id: params[:space_id]) if params[:space_id].present?
      scope = scope.where(user_id: params[:user_id]) if params[:user_id].present?
      scope = scope.where("transactions.description ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:q])}%") if params[:q].present?
      @transactions = paginate(scope)
    end
  end
end
