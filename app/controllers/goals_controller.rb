# frozen_string_literal: true

class GoalsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_account, only: [ :show, :edit, :update ]

  def index
    @goals = current_space.goals.includes(:account).order(created_at: :desc)
    @progresses = @goals.map { |goal| GoalProgress.new(goal) }
    @total_current = @progresses.sum(&:current)
    @total_target = @progresses.sum(&:target)
    # Every goal met: the list celebrates instead of totalling.
    @all_reached = @progresses.any? && @progresses.all?(&:settled?)
  end

  def show
    @progress = GoalProgress.new(@account.goal) if @account.goal
    load_transactions_timeline(@account.transactions)

    respond_to do |format|
      format.html
      format.turbo_stream if @page > 1
    end
  end

  def new
    # Starter cards on the empty state prefill the name; everything else is typed.
    build_form(goal_name: params[:goal_name])
  end

  def edit
    build_form(
      goal_name: @account.goal&.name,
      account_name: @account.name,
      current_balance: @account.balance,
      target_amount: @account.goal&.target_amount,
      deadline: @account.goal&.deadline
    )
  end

  def create
    build_form(goal_params)

    if @form.submit
      redirect_with_reload_to goal_path(id: @form.account.id), notice: t(".success"), status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Error in GoalsController#create: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to new_goal_path, alert: t(".error"), status: :see_other
  end

  def update
    build_form(goal_params)

    if @form.submit
      redirect_with_reload_to goal_path(id: @account.id), notice: t(".success"), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Error in GoalsController#update: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to edit_goal_path(@account), alert: t(".error"), status: :see_other
  end

  private

  def set_account
    @account = current_space.accounts.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to goals_path, alert: t("goals.errors.not_found")
  end

  def build_form(payload = {})
    @form = GoalForm.new(current_space, payload)
  end

  def goal_params
    params.require(:goal).permit(
      :goal_name,
      :account_name,
      :current_balance,
      :target_amount,
      :deadline
    )
  end
end
