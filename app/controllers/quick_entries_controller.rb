# frozen_string_literal: true

# Quick add: parse one natural-language utterance and, when confident, auto-create the
# transaction; otherwise fall back to the manual form prefilled with whatever was parsed.
class QuickEntriesController < ApplicationController
  before_action :authenticate_user!

  # The dictation sheet: the "+" FAB's single destination.
  def new
    @context = resolve_context
  end

  def create
    @context = resolve_context
    result = QuickEntry::Coordinator.call(params[:text].to_s, space: current_space,
                                          locale: I18n.locale, context: coordinator_context)
    draft = result.draft
    build_form(draft)

    if draft.confident? && @form.submit
      attempt = log_attempt(draft, result.ai_draft, @form.transaction)
      QuickEntry::LearnTransactionJob.perform_later(@form.transaction.id, ai_assist: true)
      Analytics.track(current_user, "quick_add_used", confident: true, ai_used: attempt&.ai_used? || false)
      Analytics.track(current_user, "transaction_created", source: "quick_add")
      redirect_with_reload_to transaction_path(id: @form.transaction.id),
                              notice: success_notice(@form.transaction), status: :see_other
    else
      attempt = log_attempt(draft, result.ai_draft, nil)
      Analytics.track(current_user, "quick_add_used", confident: false, ai_used: attempt&.ai_used? || false)
      # Carried through the form so the transaction the user completes links back to this
      # attempt — their manual choices (e.g. the category) are the correction signal.
      @form.quick_entry_attempt_id = attempt&.id
      # `update` keeps the <turbo-frame id="transaction_form"> element (replace would destroy
      # it), so the fallback form's submit stays frame-scoped and the redirect to the
      # transaction detail triggers frame-missing → full visit in bottom_sheet_controller.
      render turbo_stream: turbo_stream.update("transaction_form", partial: "transactions/form")
    end
  end

  private

  # One pill max: goal > person > account, always space-scoped records.
  Context = Struct.new(:type, :record, keyword_init: true)

  def resolve_context
    if params[:goal_id].present?
      goal = current_space.goals.find_by(id: params[:goal_id])
      return Context.new(type: :goal, record: goal) if goal
    end
    if params[:debt_id].present?
      debt = current_space.debts.find_by(id: params[:debt_id])
      return Context.new(type: :person, record: debt) if debt
    end
    if params[:account_id].present?
      account = current_space.accounts.find_by(id: params[:account_id])
      return Context.new(type: :account, record: account) if account
    end
    nil
  end

  def coordinator_context
    case @context&.type
    when :goal then { to_account_name: @context.record.account.name }
    when :person then { contact_name: @context.record.name }
    when :account then { account_name: @context.record.name }
    else {}
    end
  end

  def build_form(draft)
    @form = TransactionForm.new(current_space, draft.to_form_payload)
    @form.user = current_user
  end

  # Best-effort: logging the attempt must never break the user's submission.
  def log_attempt(draft, ai_draft, transaction)
    return if params[:text].blank?

    QuickEntryAttempt.record(
      space: current_space, user: current_user, text: params[:text].to_s,
      locale: I18n.locale, draft: draft, ai_draft: ai_draft, transaction: transaction
    )
  rescue StandardError => e
    Rails.logger.warn("quick-entry attempt logging failed: #{e.message}")
    nil
  end

  def success_notice(transaction)
    t("quick_entries.create.created",
      category: transaction.transaction_type.name,
      amount: helpers.format_money(transaction.amount, current_space.currency))
  end
end
