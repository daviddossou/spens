# frozen_string_literal: true

class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :build_form, only: [ :new ]
  before_action :set_transaction, only: [ :show, :edit, :update, :destroy ]

  def new
    respond_to do |format|
      format.html
      format.turbo_stream { render turbo_stream: turbo_stream.replace("transaction_form", partial: "form") }
    end
  end

  def create
    build_form(transaction_params)

    if @form.submit
      link_quick_entry_attempt
      QuickEntry::DescriptionLearner.learn(@form.transaction)
      redirect_with_reload_to transaction_path(id: @form.transaction.id), notice: t(".success"), status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def edit
    build_form_for_edit
  end

  def update
    build_form_for_edit(update_params.to_h.symbolize_keys)

    if @form.submit
      QuickEntry::CorrectionLearner.learn(@transaction)
      QuickEntry::DescriptionLearner.learn(@transaction)
      redirect_with_reload_to transaction_path(id: @transaction.id), notice: t(".success"), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    DestroyTransactionService.new(@transaction).call
    redirect_to dashboard_path, notice: t(".success"), status: :see_other
  end

  private

  def set_transaction
    @transaction = current_space.transactions.includes(:transaction_type, :account, :debt).find(params[:id])
  end

  def build_form(payload = {})
    # POST body (payload) wins over carried query params; kind defaults to expense.
    merged = carried_params.merge(payload.to_h.symbolize_keys)
    merged[:kind] = merged[:kind].presence || "expense"

    @form = TransactionForm.new(current_space, merged)
    @form.user = current_user
  end

  def build_form_for_edit(payload = {})
    merged = carried_params.merge(payload.to_h.symbolize_keys)
    @form = TransactionForm.new(current_space, merged.merge(transaction: @transaction))
    @form.user = current_user
  end

  # Top-level params carried across a kind switch. Read directly (not via permit)
  # so the nested :transaction isn't logged as unpermitted on create/update.
  CARRIED_PARAM_KEYS = %i[
    kind account_id debt_id direction contact_name
    amount account_name from_account_name to_account_name note description
  ].freeze

  def carried_params
    CARRIED_PARAM_KEYS.index_with { |key| params[key] }.compact
  end

  def transaction_params
    params.require(:transaction).permit(
      :kind,
      :account_name,
      :from_account_name,
      :to_account_name,
      :amount,
      :fee_amount,
      :transaction_date,
      :transaction_type_name,
      :note,
      :debt_id,
      :description,
      :contact_name,
      :direction,
      :quick_entry_attempt_id
    )
  end

  # The quick-entry fallback prefilled this form: link the created transaction back to the
  # attempt so what the user completed (e.g. the category they picked) feeds the learning
  # loop. Best-effort — never breaks the submission.
  def link_quick_entry_attempt
    id = params.dig(:transaction, :quick_entry_attempt_id)
    return if id.blank?

    attempt = QuickEntryAttempt.find_by(id: id, space: current_space, transaction_id: nil)
    return unless attempt

    attempt.update!(transaction_id: @form.transaction.id)
    QuickEntry::CorrectionLearner.learn(@form.transaction)
  rescue StandardError => e
    Rails.logger.warn("quick-entry attempt linking failed: #{e.message}")
  end

  def update_params
    params.require(:transaction).permit(
      :kind, :amount, :description, :transaction_type_name, :transaction_date,
      :account_name, :from_account_name, :to_account_name,
      :note, :debt_id, :contact_name, :direction, :fee_amount
    )
  end
end
