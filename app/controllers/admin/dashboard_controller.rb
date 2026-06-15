# frozen_string_literal: true

module Admin
  # Admin home: cheap system + learning-loop metrics and a shortlist of the strongest candidates
  # waiting for review.
  class DashboardController < BaseController
    def show
      @counts = {
        users: User.count,
        spaces: Space.count,
        transactions: Transaction.count,
        accounts: Account.count,
        debts: Debt.count
      }

      @attempts_by_outcome = QuickEntryAttempt.group(:outcome).count
      @attempts_total = @attempts_by_outcome.values.sum
      @ai_assisted = QuickEntryAttempt.where(ai_used: true).count

      @vocab = {
        aliases: LearnedAlias.group(:state).count,
        keywords: LearnedKeyword.group(:state).count
      }

      @top_candidates = (LearnedAlias.candidate.to_a + LearnedKeyword.candidate.to_a)
        .sort_by { |row| -row.confirmations }
        .first(8)
    end
  end
end
