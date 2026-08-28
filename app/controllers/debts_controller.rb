# frozen_string_literal: true

class DebtsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_debt, only: [ :show, :edit, :update ]

  def index
    # One card per person: both directions fold into a net relation, sectioned by
    # the side the net lands on, highest first. The two totals sum the nets.
    relations = DebtRelation.all_ongoing(current_space).select { |r| r.net_amount.positive? }
    @owed_to_me = relations.select { |r| r.net_direction == "lent" }.sort_by { |r| -r.net_amount }
    @i_owe = relations.select { |r| r.net_direction == "borrowed" }.sort_by { |r| -r.net_amount }
    @total_owed_to_me = @owed_to_me.sum(&:net_amount)
    @total_i_owe = @i_owe.sum(&:net_amount)
    # Closed debts (settled or written off) stay reachable as history, out of the totals.
    @closed_debts = current_space.debts.where.not(status: "ongoing").order(updated_at: :desc)
  end

  def show
    # The page is the relation, not one folder: a two-way person shows a net hero
    # and a merged timeline across both directions.
    @relation = DebtRelation.for(@debt)
    load_transactions_timeline(@relation.transactions)

    respond_to do |format|
      format.html
      format.turbo_stream if @page > 1
    end
  end

  def new
    # Can be opened prequalified from a person's page (contact_name prefilled).
    build_form(direction: params[:direction] || "lent", contact_name: params[:contact_name])
  end

  def create
    build_form(debt_params)

    if @form.submit
      redirect_with_reload_to debt_path(id: @form.debt.id), notice: t(".success"), status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Error in DebtsController#create: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to new_debt_path, alert: t(".error"), status: :see_other
  end

  def edit
    @form = DebtForm.new(current_space, debt_edit_payload)
    @form.user = current_user
  end

  def update
    build_form(debt_params.merge(id: @debt.id))

    if @form.submit
      redirect_with_reload_to debt_path(id: @debt.id), notice: t(".success"), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Error in DebtsController#update: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to edit_debt_path(@debt), alert: t(".error"), status: :see_other
  end

  private

  def set_debt
    @debt = current_space.debts.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to debts_path, alert: t("debts.errors.not_found")
  end

  def build_form(payload = {})
    @form = DebtForm.new(current_space, payload)
    @form.user = current_user
  end

  def debt_edit_payload
    {
      id: @debt.id,
      contact_name: @debt.name,
      total_lent: @debt.total_lent,
      total_reimbursed: @debt.total_reimbursed,
      note: @debt.note,
      direction: @debt.direction,
      deadline: @debt.deadline
    }
  end

  def debt_params
    params.require(:debt).permit(
      :id,
      :contact_name,
      :total_lent,
      :total_reimbursed,
      :note,
      :direction,
      :account_name,
      :deadline
    )
  end
end
