# frozen_string_literal: true

class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :build_form, only: [ :new ]
  before_action :set_transaction, only: [ :show, :edit, :update, :destroy ]
  helper_method :carried_params, :phrase_context_key

  def new
    respond_to do |format|
      format.html
      format.turbo_stream { render turbo_stream: turbo_stream.replace("transaction_form", partial: "form") }
    end
  end

  def create
    build_form(transaction_params)
    phrase = params[:text].to_s.strip.presence
    parse = phrase && parse_phrase(phrase, ai: @form.transaction_type_name.blank? && !@form.transfer? && !@form.debt_transaction?)
    fill_category_gap(parse.draft) if parse

    if @form.submit
      if parse
        attempt = link_quick_entry_attempt || log_attempt(phrase, parse)
        # correction: what the user changed in the form before saving, against the parse, is
        # the learning signal now that the phrase fills the form live.
        QuickEntry::LearnTransactionJob.perform_later(@form.transaction.id, ai_assist: true, correction: true)
        Analytics.track(current_user, "quick_add_used", confident: true, ai_used: attempt&.ai_used? || false)
        Analytics.track(current_user, "transaction_created", source: "quick_add")
      else
        link_quick_entry_attempt
        QuickEntry::LearnTransactionJob.perform_later(@form.transaction.id, correction: true)
        Analytics.track(current_user, "transaction_created", source: "manual")
      end
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
      QuickEntry::LearnTransactionJob.perform_later(@transaction.id, correction: true)
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

  # Precedence, lowest first: carried query params < what the phrase parsed <
  # fields the user set by hand (locked) < the POST body. Kind defaults to expense.
  def build_form(payload = {})
    # POST body (payload) wins over carried query params; kind defaults to expense.
    merged = carried_params.merge(payload.to_h.symbolize_keys)
    merged[:kind] = merged[:kind].presence || "expense"

    @form = TransactionForm.new(current_space, merged)
    @form.user = current_user

    # Opened from a person's page: the "who" is known, so the field hides and the
    # cards lock open. Keep the relation for the header balance line.
    @person_locked = merged[:person_locked].present? && merged[:contact_name].present?
    @relation = DebtRelation.new(space: current_space, name: merged[:contact_name]) if @person_locked
  end

  def build_form_for_edit(payload = {})
    merged = carried_params.merge(payload.to_h.symbolize_keys)
    @form = TransactionForm.new(current_space, merged.merge(transaction: @transaction))
    @form.user = current_user
  end

  # Top-level params carried across a kind switch. Read directly (not via permit)
  # so the nested :transaction isn't logged as unpermitted on create/update.
  CARRIED_PARAM_KEYS = %i[
    kind account_id debt_id direction contact_name person_locked
    amount account_name from_account_name to_account_name note description
  ].freeze

  def carried_params
    CARRIED_PARAM_KEYS.index_with { |key| params[key] }.compact
  end
    @form.quick_entry_attempt_id = @phrase_attempt.id if @phrase_attempt

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
  PARSED_KEYS = %i[
    kind amount account_name from_account_name to_account_name transaction_type_name
    fee_amount transaction_date note label contact_name direction debt_id
  ].freeze

  def locked_params
    return {} unless params[:locked].is_a?(ActionController::Parameters)

    params[:locked].permit(*PARSED_KEYS).to_h.symbolize_keys.compact_blank
  end

  # A bare phrase ("2000 zem") parses as an expense by default; only a category or an
  # explicit signal lets the phrase override the kind the page opened with.
  def phrase_decided_kind?(parsed)
    parsed[:transaction_type_name].present? || parsed[:kind] != "expense"
  end

  def parse_phrase(text, ai:)
    QuickEntry::Coordinator.call(text, space: current_space, locale: I18n.locale,
                                 context: phrase_context, ai: ai)
  end

  # Worth an AI call: an amount is in and there's at least a word around it — never "A", never
  # a bare number, which the rules already read for free.
  def phrase_settled?(draft)
    draft.amount.present? && @text.split.size >= 2
  end

  # Which example the phrase field shows: the page it opened from.
  def phrase_context_key
    ctx = phrase_context
    return :goal if ctx[:to_account_name]
    return :person if ctx[:contact_name]
    return :account if ctx[:account_name]

    :none
  end

  # The page the form opened from: a goal's account (deposit), a person, or an account.
  def phrase_context
    carried = carried_params
    if carried[:person_locked].present? && carried[:contact_name].present?
      { contact_name: carried[:contact_name] }
    elsif carried[:account_id].present?
      account = current_space.accounts.find_by(id: carried[:account_id])
      return {} unless account

      carried[:kind] == "transfer" ? { to_account_name: account.name } : { account_name: account.name }
    else
      {}
    end
  end

  # Submitted without a category: let the AI name one from the phrase, as quick add did.
  def fill_category_gap(draft)
    return if @form.transaction_type_name.present? || draft.transaction_type_name.blank?
    return unless %w[expense income].include?(@form.kind)

    @form.transaction_type_name = draft.transaction_type_name
    @form.label ||= draft.label
  end

  # Best-effort: logging the attempt must never break the user's submission.
  def log_attempt(text, parse)
    QuickEntryAttempt.record(
      space: current_space, user: current_user, text: text, locale: I18n.locale,
      draft: parse.draft, ai_draft: parse.ai_draft, transaction: @form&.transaction
    )
  rescue StandardError => e
    Rails.logger.warn("quick-entry attempt logging failed: #{e.message}")
    nil
  end

    id = params.dig(:transaction, :quick_entry_attempt_id)
    return if id.blank?

    attempt = QuickEntryAttempt.find_by(id: id, space: current_space, transaction_id: nil)
    return unless attempt

    attempt.update!(transaction_id: @form.transaction.id, source: attempt.ai_used? ? "ai" : "rules")
    attempt
    # The correction learning runs in LearnTransactionJob (enqueued in #create), after the
    # attempt is linked here — so it sees the link and stays off the request path.
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
    nil
