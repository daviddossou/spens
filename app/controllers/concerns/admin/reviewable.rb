# frozen_string_literal: true

module Admin
  # Shared index + approve/reject/restore behaviour for the two learned-vocabulary review screens
  # (aliases and keywords). Each including controller supplies `reviewable_model` and the audit
  # action names. Approve/reject flip the row's state, write an audit entry, and turbo-replace the
  # row in place — with an inline Undo — so the admin sees it move without a reload.
  module Reviewable
    extend ActiveSupport::Concern

    STATES = %w[candidate active rejected].freeze

    included do
      before_action :set_record, only: %i[approve reject restore]
    end

    def index
      @state = params[:state].presence_in(STATES) || "candidate"
      # Global tier only: personal (space-scoped) rows are the user's own vocabulary, managed
      # from the space settings screen — not subject to admin review.
      scope = reviewable_model.global.where(state: @state).order(confirmations: :desc, created_at: :desc)
      if params[:q].present?
        scope = scope.where("phrase ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:q])}%")
      end
      @state_counts = reviewable_model.global.group(:state).count
      @records = paginate(scope)
      # Utterance samples are review context — only worth the scan for candidates.
      @samples = @state == "candidate" ? sample_utterances(@records) : {}
      render "admin/shared/review_list"
    end

    # Approves the candidate, optionally applying the reviewer's edits first (a fixed-up
    # phrase or a retargeted category/kind from the inline form on the row).
    def approve
      @record.assign_attributes(approved_overrides.merge(state: "active"))
      if @record.save
        record_admin_action(approve_action, target: @record)
        respond_review
      else
        redirect_back fallback_location: reviewable_index_path,
                      alert: @record.errors.full_messages.to_sentence
      end
    end

    def reject
      prev_state = @record.state
      @record.reject!
      record_admin_action(reject_action, target: @record)
      respond_review(undo_state: prev_state)
    end

    # Undo for a just-rejected row: puts it back in the state it was rejected from.
    def restore
      @record.update!(state: params[:undo_state].presence_in(%w[candidate active]) || "candidate")
      record_admin_action(restore_action, target: @record)
      respond_review
    end

    private

    def set_record
      @record = reviewable_model.find(params[:id])
    end

    def approved_overrides
      overrides = {}
      overrides[:phrase] = CategoryText.normalize(params[:phrase]) if params[:phrase].present?

      if @record.is_a?(LearnedAlias) && params[:taxonomy_key].present? && TransactionTaxonomy.exists?(params[:taxonomy_key])
        overrides[:taxonomy_key] = params[:taxonomy_key]
      elsif @record.is_a?(LearnedKeyword) && LearnedKeyword::KINDS.include?(params[:kind])
        overrides[:kind] = params[:kind]
      end

      overrides
    end

    # Best-effort { record.id => [utterance, ...] }: there's no FK from a learned row back to the
    # attempts that taught it, so we scan a recent window of attempts and keep those whose
    # normalized text contains the candidate phrase. Good enough to give a reviewer context.
    def sample_utterances(records, limit: 3, window: 500)
      return {} if records.empty?

      recent = QuickEntryAttempt.order(created_at: :desc).limit(window).pluck(:text)
                                .map { |text| [ CategoryText.normalize(text), text ] }
      records.each_with_object({}) do |row, acc|
        acc[row.id] = recent.select { |norm, _| norm.include?(row.phrase) }.first(limit).map(&:last)
      end
    end

    def respond_review(undo_state: nil)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            @record, partial: "admin/shared/learned_row", locals: { row: @record, undo_state: undo_state }
          )
        end
        format.html { redirect_back fallback_location: reviewable_index_path }
      end
    end
  end
end
