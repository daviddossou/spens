# frozen_string_literal: true

class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :build_form, only: [ :new ]

  def new
    respond_to do |format|
      format.html
      format.turbo_stream { render turbo_stream: turbo_stream.replace("transaction_form", partial: "form") }
    end
  end

  def create
    build_form(transaction_params)

    if @form.submit
      redirect_with_reload_to dashboard_path, notice: t(".success"), status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @transaction = current_user.transactions.includes(:transaction_type, :account, :debt).find(params[:id])
  end

  private

  def build_form(payload = {})
    kind = params[:kind] || payload[:kind] || "expense"
    account_id = params[:account_id] || payload[:account_id]
    debt_id = params[:debt_id] || payload[:debt_id]

    @form = TransactionForm.new(
      current_user,
      payload.merge(kind: kind, account_id: account_id, debt_id: debt_id)
    )
  end

  def transaction_params
    params.require(:transaction).permit(
      :kind,
      :account_name,
      :from_account_name,
      :to_account_name,
      :amount,
      :transaction_date,
      :transaction_type_name,
      :note,
      :debt_id
    )
  end
end
