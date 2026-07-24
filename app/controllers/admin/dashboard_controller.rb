# frozen_string_literal: true

module Admin
  # Admin home = the daily workbench inbox: pending corrections and the strongest candidates
  # front and centre, system metrics demoted below.
  class DashboardController < BaseController
    include CorrectionHints

    INBOX_LIMIT = 5

    def show
      @pending_corrections = QuickEntryAttempt.needs_review.includes(:user, :space)
                                              .order(created_at: :desc).limit(INBOX_LIMIT)
      @pending_corrections_count = QuickEntryAttempt.needs_review.count
      @hints = @pending_corrections.index_with { |attempt| hint_for(attempt) }

      @top_candidates = (LearnedAlias.global.candidate.to_a + LearnedKeyword.global.candidate.to_a)
        .sort_by { |row| -row.confirmations }
        .first(8)

      @vocab = {
        aliases: LearnedAlias.group(:state).count,
        keywords: LearnedKeyword.group(:state).count
      }

      @counts = {
        users: User.count,
        spaces: Space.count,
        transactions: Transaction.count,
        accounts: Account.count,
        debts: Debt.count
      }
      @attempts_by_outcome = QuickEntryAttempt.group(:outcome).count
      @attempts_total = @attempts_by_outcome.values.sum
    end
  end
end
