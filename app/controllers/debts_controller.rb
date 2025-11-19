# frozen_string_literal: true

class DebtsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_debt, only: [:show]

  def index
    @debts = current_user.debts.ongoing.order(created_at: :desc)
  end

  def show
    @latest_transactions = @debt.transactions.order(transaction_date: :desc).limit(10)
  end

  def new
    build_form
  end

  def create
    build_form(debt_params)

    if @form.submit
      redirect_to debts_path, notice: t('.success')
    else
      render :new, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Error in DebtsController#create: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to new_debt_path, alert: t('.error')
  end

  private

  def set_debt
    @debt = current_user.debts.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to debts_path, alert: t('debts.errors.not_found')
  end

  def build_form(payload = {})
    @form = DebtForm.new(current_user, payload)
  end

  def debt_params
    params.require(:debt).permit(
      :contact_name,
      :total_lent,
      :total_reimbursed,
      :note
    )
  end
end
