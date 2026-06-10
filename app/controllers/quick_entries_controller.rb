# frozen_string_literal: true

# Quick add: parse one natural-language utterance and, when confident, auto-create the
# transaction; otherwise fall back to the manual form prefilled with whatever was parsed.
class QuickEntriesController < ApplicationController
  before_action :authenticate_user!

  # Renders the quick-add modal (its own FAB, separate from the manual "+").
  def new
  end

  def create
    draft = QuickEntry::Coordinator.call(params[:text].to_s, space: current_space, locale: I18n.locale)
    build_form(draft)

    if draft.confident? && @form.submit
      log_attempt(draft, @form.transaction)
      redirect_with_reload_to transaction_path(id: @form.transaction.id),
                              notice: success_notice(@form.transaction), status: :see_other
    else
      log_attempt(draft, nil)
      render turbo_stream: turbo_stream.replace("transaction_form", partial: "transactions/form")
    end
  end

  private

  def build_form(draft)
    @form = TransactionForm.new(current_space, draft.to_form_payload)
    @form.user = current_user
  end

  # Best-effort: logging the attempt must never break the user's submission.
  def log_attempt(draft, transaction)
    return if params[:text].blank?

    QuickEntryAttempt.record(
      space: current_space, user: current_user, text: params[:text].to_s,
      locale: I18n.locale, draft: draft, transaction: transaction
    )
  rescue StandardError => e
    Rails.logger.warn("quick-entry attempt logging failed: #{e.message}")
  end

  def success_notice(transaction)
    t("quick_entries.create.created",
      category: transaction.transaction_type.name,
      amount: helpers.format_money(transaction.amount, current_space.currency))
  end
end
