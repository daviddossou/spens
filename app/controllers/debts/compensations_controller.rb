# frozen_string_literal: true

module Debts
  # Offsetting the two sides of a two-way relation is its own action, kept out of
  # DebtsController so that one stays about a single debt's CRUD.
  class CompensationsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_debt

    def create
      relation = DebtRelation.for(@debt)
      if CompensateDebtsService.new(relation, user: current_user).call
        redirect_with_reload_to debt_path(id: relation.primary_debt.id), notice: t("debts.compensate.success"), status: :see_other
      else
        redirect_to debt_path(id: @debt.id), alert: t("debts.compensate.error"), status: :see_other
      end
    end

    private

    def set_debt
      @debt = current_space.debts.find(params[:debt_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to debts_path, alert: t("debts.errors.not_found")
    end
  end
end
