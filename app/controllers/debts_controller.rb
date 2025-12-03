# frozen_string_literal: true

class DebtsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_debt, only: [:show, :edit, :update]

  def index
    @direction = params[:direction] || 'lent'
    @debts = current_user.debts.ongoing.send(@direction).order(created_at: :desc)
  end

  def show
    @latest_transactions = @debt.transactions.order(transaction_date: :desc).limit(10)
  end

  def new
    build_form(direction: params[:direction] || 'lent')
  end

  def create
    build_form(debt_params)

    if @form.submit
      redirect_to debt_path(id: @form.debt.id), notice: t('.success')
    else
      render :new, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Error in DebtsController#create: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to new_debt_path, alert: t('.error')
  end

  def edit
    @form = DebtForm.new(current_user, debt_edit_payload)
  end

  def update
    build_form(debt_params.merge(id: @debt.id))

    if @form.submit
      redirect_to debt_path(id: @debt.id), notice: t('.success')
    else
      render :edit, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Error in DebtsController#update: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to edit_debt_path(@debt), alert: t('.error')
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

  def debt_edit_payload
    {
      id: @debt.id,
      contact_name: @debt.name,
      total_lent: @debt.total_lent,
      total_reimbursed: @debt.total_reimbursed,
      note: @debt.note,
      direction: @debt.direction
    }
  end

  def debt_params
    params.require(:debt).permit(
      :id,
      :contact_name,
      :total_lent,
      :total_reimbursed,
      :note,
      :direction
    )
  end
end
