# frozen_string_literal: true

class GoalsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_account, only: [:show, :edit, :update]

  def index
    @accounts_with_goals = current_user.accounts.with_saving_goals.order(created_at: :desc)
  end

  def show
    @latest_transactions = @account.transactions.order(transaction_date: :desc).limit(10)
  end

  def new
    build_form
  end

  def edit
    build_form(
      account_name: @account.name,
      current_balance: @account.balance,
      saving_goal: @account.saving_goal
    )
  end

  def create
    build_form(goal_params)

    if @form.submit
      redirect_to goals_path, notice: t('.success')
    else
      render :new, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Error in GoalsController#create: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to new_goal_path, alert: t('.error')
  end

  def update
    build_form(goal_params)

    if @form.submit
      redirect_to goal_path(id: @account.id), notice: t('.success')
    else
      render :edit, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Error in GoalsController#update: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to edit_goal_path(@account), alert: t('.error')
  end

  private

  def set_account
    @account = current_user.accounts.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to goals_path, alert: t('goals.errors.not_found')
  end

  def build_form(payload = {})
    @form = GoalForm.new(current_user, payload)
  end

  def goal_params
    params.require(:goal).permit(
      :account_name,
      :current_balance,
      :saving_goal
    )
  end
end
