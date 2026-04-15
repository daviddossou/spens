# frozen_string_literal: true

class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :build_form, only: [ :new ]
  before_action :set_transaction, only: [ :show, :edit, :update, :destroy ]

  def new
    respond_to do |format|
      format.html
      format.turbo_stream { render turbo_stream: turbo_stream.replace("transaction_form", partial: "form") }
    end
  end

  def create
    build_form(transaction_params)

    if @form.submit
      redirect_with_reload_to transaction_path(id: @form.transaction.id), notice: t(".success"), status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def edit
    build_form_for_edit
  end

  def update
    build_form_for_edit(update_params.to_h.symbolize_keys)

    if @form.submit
      redirect_with_reload_to transaction_path(id: @transaction.id), notice: t(".success"), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @transaction.destroy!
    redirect_to dashboard_path, notice: t(".success"), status: :see_other
  end

  private

  def set_transaction
    @transaction = current_space.transactions.includes(:transaction_type, :account, :debt).find(params[:id])
  end

  def build_form(payload = {})
    kind = params[:kind] || payload[:kind] || "expense"
    account_id = params[:account_id] || payload[:account_id]
    debt_id = params[:debt_id] || payload[:debt_id]

    @form = TransactionForm.new(
      current_space,
      payload.merge(kind: kind, account_id: account_id, debt_id: debt_id)
    )
    @form.user = current_user
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
      :debt_id,
      :description
    )
  end

  def update_params
    params.require(:transaction).permit(:kind, :amount, :description, :transaction_type_name, :transaction_date, :account_name)
  end

  def build_form_for_edit(payload = {})
    @form = TransactionForm.new(current_space, payload.merge(transaction: @transaction))
    @form.user = current_user
  end
end
