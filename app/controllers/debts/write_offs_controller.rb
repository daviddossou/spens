# frozen_string_literal: true

module Debts
  # Writing off a debt — a receivable that won't come back, or a debt forgiven —
  # is its own action, kept out of DebtsController so that one stays about the
  # debt's CRUD.
  class WriteOffsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_debt

    def create
      if WriteOffDebtService.new(@debt, user: current_user).call
        redirect_with_reload_to debt_path(id: @debt.id), notice: t("debts.write_off.success"), status: :see_other
      else
        redirect_to debt_path(id: @debt.id), alert: t("debts.write_off.error"), status: :see_other
      end
    end

    private

    def set_debt
      @debt = current_space.debts.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to debts_path, alert: t("debts.errors.not_found")
    end
  end
end
