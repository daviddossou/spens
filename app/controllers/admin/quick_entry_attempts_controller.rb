# frozen_string_literal: true

module Admin
  # The learning-loop monitor: every quick-add submission, what produced it, and what the user
  # did with it.
  class QuickEntryAttemptsController < BaseController
    def index
      scope = QuickEntryAttempt.includes(:user, :space, :created_transaction).order(created_at: :desc)
      scope = scope.where(outcome: params[:outcome]) if params[:outcome].present?
      scope = scope.where(source: params[:source]) if params[:source].present?
      @attempts = paginate(scope)
    end
  end
end
