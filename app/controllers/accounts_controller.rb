# frozen_string_literal: true

class AccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_account, only: [ :show, :edit, :update, :destroy ]

  def index
    @accounts = current_user.accounts.order(created_at: :desc)
  end

  def show
    @latest_transactions = @account.transactions
      .includes(:transaction_type, :account, :debt)
      .order(transaction_date: :desc)
      .limit(10)
  end

  def new
    build_form
  end

  def create
    build_form(account_params)

    if @form.submit
      redirect_to account_path(id: @form.account.id), notice: t(".success"), status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Error in AccountsController#create: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to new_account_path, alert: t(".error"), status: :see_other
  end

  def edit
    @form = AccountForm.new(current_user, account_edit_payload)
  end

  def update
    build_form(account_params.merge(id: @account.id))

    if @form.submit
      redirect_to account_path(id: @account.id), notice: t(".success"), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Error in AccountsController#update: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to edit_account_path(@account), alert: t(".error"), status: :see_other
  end

  def destroy
    if @account.transactions.exists?
      redirect_to account_path(id: @account.id), alert: t(".has_transactions"), status: :see_other
    else
      @account.destroy!
      redirect_to accounts_path, notice: t(".success"), status: :see_other
    end
  rescue StandardError => e
    Rails.logger.error "Error in AccountsController#destroy: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to accounts_path, alert: t(".error"), status: :see_other
  end

  private

  def set_account
    @account = current_user.accounts.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to accounts_path, alert: t("accounts.errors.not_found")
  end

  def build_form(payload = {})
    @form = AccountForm.new(current_user, payload)
  end

  def account_edit_payload
    {
      id: @account.id,
      account_name: @account.name,
      current_balance: @account.balance,
      saving_goal: @account.saving_goal
    }
  end

  def account_params
    params.require(:account).permit(
      :account_name,
      :current_balance,
      :saving_goal
    )
  end
end
