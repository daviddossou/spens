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
      redirect_to new_transaction_path, notice: t('.success')
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def build_form(payload = {})
    kind = params[:kind] || payload[:kind] || 'expense'
    @form = TransactionForm.new(current_user, payload.merge(kind: kind))
  end

  def transaction_params
    params.require(:transaction).permit(
      :kind,
      :account_name,
      :amount,
      :transaction_date,
      :transaction_type_name,
      :note
    )
  end
end
