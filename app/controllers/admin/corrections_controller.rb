# frozen_string_literal: true

module Admin
  # Human-in-the-loop teaching: every edited quick-entry attempt (original phrase → parser
  # guess → user's correction), with a form to attach an expression to a category or kind
  # directly. The extractor's residual phrase and any auto-mined candidate are pre-filled as
  # hints; what the admin submits is written straight to `active`.
  class CorrectionsController < BaseController
    include CorrectionHints

    STATES = %w[pending reviewed].freeze

    def index
      @state = params[:state].presence_in(STATES) || "pending"
      scope = @state == "pending" ? QuickEntryAttempt.needs_review : QuickEntryAttempt.reviewed
      @attempts = paginate(scope.includes(:user, :space).order(created_at: :desc))
      @hints = @attempts.index_with { |attempt| hint_for(attempt) }
    end

    def teach
      attempt = QuickEntryAttempt.find(params[:id])
      row = teach_row
      if row
        record_admin_action("teach_correction", target: row, metadata: { attempt_id: attempt.id })
        attempt.mark_reviewed!
        redirect_to admin_corrections_path, notice: t("admin.corrections.taught", phrase: row.phrase)
      else
        redirect_to admin_corrections_path, alert: t("admin.corrections.invalid")
      end
    end

    def dismiss
      attempt = QuickEntryAttempt.find(params[:id])
      attempt.mark_reviewed!
      record_admin_action("dismiss_correction", target: attempt)
      redirect_to admin_corrections_path, notice: t("admin.corrections.dismissed")
    end

    private

    def teach_row
      phrase = params[:phrase].to_s.strip
      return nil if phrase.blank?

      if params[:taxonomy_key].present?
        return nil unless TransactionTaxonomy.exists?(params[:taxonomy_key])

        LearnedAlias.admin_teach(phrase: phrase, taxonomy_key: params[:taxonomy_key])
      elsif params[:kind].present?
        return nil unless LearnedKeyword::KINDS.include?(params[:kind])

        LearnedKeyword.admin_teach(phrase: phrase, kind: params[:kind])
      end
    end
  end
end
