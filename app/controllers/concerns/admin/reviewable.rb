# frozen_string_literal: true

module Admin
  # Shared index + approve/reject behaviour for the two learned-vocabulary review screens
  # (aliases and keywords). Each including controller supplies `reviewable_model` and the audit
  # action names. Approve/reject flip the row's state, write an audit entry, and turbo-replace the
  # row in place so the admin sees it move between states without a reload.
  module Reviewable
    extend ActiveSupport::Concern

    STATES = %w[candidate active rejected].freeze

    included do
      before_action :set_record, only: %i[approve reject]
    end

    def index
      @state = params[:state].presence_in(STATES) || "candidate"
      @records = reviewable_model.where(state: @state).order(confirmations: :desc, created_at: :desc)
      @samples = sample_utterances(@records)
      render "admin/shared/review_list"
    end

    def approve
      @record.approve!
      record_admin_action(approve_action, target: @record)
      respond_review
    end

    def reject
      @record.reject!
      record_admin_action(reject_action, target: @record)
      respond_review
    end

    private

    def set_record
      @record = reviewable_model.find(params[:id])
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

    def respond_review
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(@record, partial: "admin/shared/learned_row", locals: { row: @record })
        end
        format.html { redirect_back fallback_location: reviewable_index_path }
      end
    end
  end
end
