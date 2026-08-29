# frozen_string_literal: true

module Accounts
  # Archiving an account: keeps its history, drops it out of the lists and entry
  # pickers. create archives, destroy brings it back.
  class ArchivesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_account

    def create
      @account.archive!
      redirect_to accounts_path, notice: t(".success", name: @account.name), status: :see_other
    end

    def destroy
      @account.reactivate!
      redirect_to account_path(id: @account.id), notice: t(".success", name: @account.name), status: :see_other
    end

    private

    def set_account
      @account = current_space.accounts.find(params[:account_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to accounts_path, alert: t("accounts.errors.not_found")
    end
  end
end
